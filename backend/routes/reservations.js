const express = require('express');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

const HOLD_MINUTES = 15; // batas waktu pembayaran
const FEE_RATE = 0.15; // pajak 10% + layanan 5%
const VIP_MIN_ORDER = 500000; // minimal order meja VIP (sebelum pajak)

// Reservasi pending yang melewati batas waktu otomatis dibatalkan
async function expireStale(db = pool) {
  await db.query(
    `UPDATE reservations SET status = 'cancelled'
     WHERE status = 'pending'
       AND created_at < LOCALTIMESTAMP - INTERVAL '${HOLD_MINUTES} minutes'`
  );
}

const SELECT_RESERVATION = `
  SELECT r.id, r.booking_code, r.table_id,
         t.name AS table_name, t.area, t.image_url AS table_image,
         to_char(r.reservation_date, 'YYYY-MM-DD') AS reservation_date,
         to_char(r.reservation_time, 'HH24:MI') AS reservation_time,
         r.guest_count, r.notes, r.status, r.total_amount, r.created_at,
         GREATEST(0, EXTRACT(EPOCH FROM (r.created_at + INTERVAL '${HOLD_MINUTES} minutes' - LOCALTIMESTAMP))::int) AS expires_in
  FROM reservations r
  JOIN restaurant_tables t ON t.id = r.table_id`;

// Ambil satu reservasi lengkap dengan daftar menu, subtotal, dan biaya
async function getReservationDetail(id, userId) {
  const r = await pool.query(SELECT_RESERVATION + ' WHERE r.id = $1 AND r.user_id = $2', [id, userId]);
  if (r.rows.length === 0) return null;
  const items = await pool.query(
    `SELECT ri.menu_item_id, m.name, m.image_url, c.name AS category_name,
            ri.quantity, ri.price, ri.note
     FROM reservation_items ri
     JOIN menu_items m ON m.id = ri.menu_item_id
     JOIN menu_categories c ON c.id = m.category_id
     WHERE ri.reservation_id = $1
     ORDER BY ri.id`,
    [id]
  );
  const subtotal = items.rows.reduce((sum, i) => sum + Number(i.price) * i.quantity, 0);
  const total = Number(r.rows[0].total_amount);
  return { ...r.rows[0], items: items.rows, subtotal, fee: total - subtotal };
}

function makeBookingCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'FB';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

// Cek ketersediaan meja: /api/reservations/availability?date=2026-12-20&time=19:00&area=Indoor
router.get('/availability', async (req, res) => {
  try {
    const { date, time, area } = req.query;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date || '') || !/^\d{2}:\d{2}$/.test(time || '')) {
      return res.status(400).json({ message: 'Format date (YYYY-MM-DD) dan time (HH:MM) wajib diisi' });
    }
    await expireStale();
    const result = await pool.query(
      `SELECT t.*,
              NOT EXISTS (
                SELECT 1 FROM reservations r
                WHERE r.table_id = t.id
                  AND r.reservation_date = $1
                  AND r.reservation_time = $2
                  AND r.status IN ('pending', 'paid')
              ) AS is_available
       FROM restaurant_tables t
       WHERE t.is_active = TRUE AND ($3::text IS NULL OR t.area = $3)
       ORDER BY t.area, t.capacity, t.id`,
      [date, time, area || null]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Buat reservasi
router.post('/', authRequired, async (req, res) => {
  const { table_id, reservation_date, reservation_time, notes } = req.body;
  const guest_count = parseInt(req.body.guest_count, 10);
  const items = Array.isArray(req.body.items) ? req.body.items : [];

  if (!table_id || !guest_count || guest_count < 1) {
    return res.status(400).json({ message: 'table_id dan guest_count wajib diisi' });
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(reservation_date || '') || !/^\d{2}:\d{2}$/.test(reservation_time || '')) {
    return res.status(400).json({ message: 'Format tanggal (YYYY-MM-DD) dan jam (HH:MM) tidak valid' });
  }

  const client = await pool.connect();
  try {
    await expireStale(client);
    await client.query('BEGIN');

    // Kunci baris meja supaya tidak ada dua reservasi bersamaan di meja yang sama
    const tableResult = await client.query(
      'SELECT * FROM restaurant_tables WHERE id = $1 AND is_active = TRUE FOR UPDATE',
      [table_id]
    );
    if (tableResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Meja tidak ditemukan' });
    }
    const table = tableResult.rows[0];

    if (guest_count > table.capacity) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: `Kapasitas ${table.name} maksimal ${table.capacity} orang` });
    }

    const future = await client.query(
      'SELECT ($1::date + $2::time) >= LOCALTIMESTAMP AS ok',
      [reservation_date, reservation_time]
    );
    if (!future.rows[0].ok) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Tanggal dan jam reservasi sudah lewat' });
    }

    const conflict = await client.query(
      `SELECT 1 FROM reservations
       WHERE table_id = $1 AND reservation_date = $2 AND reservation_time = $3
         AND status IN ('pending', 'paid')`,
      [table_id, reservation_date, reservation_time]
    );
    if (conflict.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ message: 'Meja sudah dipesan pada waktu tersebut' });
    }

    // Hitung subtotal dari harga menu di database
    const lines = [];
    for (const item of items) {
      const qty = parseInt(item.quantity, 10);
      if (!item.menu_item_id || !qty || qty < 1) {
        await client.query('ROLLBACK');
        return res.status(400).json({ message: 'Data menu pesanan tidak valid' });
      }
      const menu = await client.query(
        'SELECT id, price FROM menu_items WHERE id = $1 AND is_available = TRUE',
        [item.menu_item_id]
      );
      if (menu.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ message: `Menu dengan id ${item.menu_item_id} tidak tersedia` });
      }
      const note = String(item.note || '').trim().slice(0, 200) || null;
      lines.push({
        menu_item_id: menu.rows[0].id,
        quantity: qty,
        price: Number(menu.rows[0].price),
        note,
      });
    }
    const subtotal = lines.reduce((sum, l) => sum + l.price * l.quantity, 0);

    // Meja VIP wajib minimal order
    if (table.area === 'VIP' && subtotal < VIP_MIN_ORDER) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        message: `Meja VIP minimal order Rp ${VIP_MIN_ORDER.toLocaleString('id-ID')}`,
      });
    }

    const fee = Math.round(subtotal * FEE_RATE);
    const total = subtotal + fee;
    // Tanpa pesanan menu tidak ada yang perlu dibayar, reservasi langsung terkonfirmasi
    const status = total === 0 ? 'paid' : 'pending';

    const code = makeBookingCode();
    const inserted = await client.query(
      `INSERT INTO reservations
         (booking_code, user_id, table_id, reservation_date, reservation_time,
          guest_count, notes, status, total_amount)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id`,
      [code, req.user.id, table_id, reservation_date, reservation_time,
        guest_count, notes || null, status, total]
    );
    const reservationId = inserted.rows[0].id;

    for (const line of lines) {
      await client.query(
        `INSERT INTO reservation_items (reservation_id, menu_item_id, quantity, price, note)
         VALUES ($1, $2, $3, $4, $5)`,
        [reservationId, line.menu_item_id, line.quantity, line.price, line.note]
      );
    }

    await client.query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [
        req.user.id,
        status === 'paid' ? 'Reservasi berhasil' : 'Reservasi dibuat',
        status === 'paid'
          ? `Reservasi ${code} untuk ${table.name} berhasil dikonfirmasi.`
          : `Reservasi ${code} untuk ${table.name} menunggu pembayaran.`,
      ]
    );

    await client.query('COMMIT');
    const detail = await getReservationDetail(reservationId, req.user.id);
    res.status(201).json(detail);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// Riwayat reservasi user: /api/reservations atau /api/reservations?status=paid
router.get('/', authRequired, async (req, res) => {
  try {
    await expireStale();
    const { status } = req.query;
    const result = status
      ? await pool.query(
          SELECT_RESERVATION + ' WHERE r.user_id = $1 AND r.status = $2 ORDER BY r.created_at DESC',
          [req.user.id, status]
        )
      : await pool.query(
          SELECT_RESERVATION + ' WHERE r.user_id = $1 ORDER BY r.created_at DESC',
          [req.user.id]
        );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Batalkan reservasi (hanya yang masih pending)
router.patch('/:id/cancel', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE reservations SET status = 'cancelled'
       WHERE id = $1 AND user_id = $2 AND status = 'pending'
       RETURNING id, booking_code`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Reservasi tidak ditemukan atau tidak bisa dibatalkan' });
    }
    await pool.query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [req.user.id, 'Reservasi dibatalkan', `Reservasi ${result.rows[0].booking_code} telah dibatalkan.`]
    );
    const detail = await getReservationDetail(req.params.id, req.user.id);
    res.json(detail);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Detail satu reservasi
router.get('/:id', authRequired, async (req, res) => {
  try {
    await expireStale();
    const detail = await getReservationDetail(req.params.id, req.user.id);
    if (!detail) return res.status(404).json({ message: 'Reservasi tidak ditemukan' });
    res.json(detail);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;