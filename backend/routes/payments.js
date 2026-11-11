const express = require('express');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

const METHODS = ['transfer', 'ovo', 'gopay', 'qris'];
const HOLD_MINUTES = 15;

async function expireStale() {
  await pool.query(
    `UPDATE reservations SET status = 'cancelled'
     WHERE status = 'pending'
       AND created_at < LOCALTIMESTAMP - INTERVAL '${HOLD_MINUTES} minutes'`
  );
  await pool.query(
    `UPDATE orders SET status = 'cancelled'
     WHERE status = 'pending'
       AND created_at < LOCALTIMESTAMP - INTERVAL '${HOLD_MINUTES} minutes'`
  );
}

// Buat pembayaran untuk reservasi (reservation_id) atau pesanan (order_id) yang masih pending
router.post('/', authRequired, async (req, res) => {
  try {
    const reservation_id = parseInt(req.body.reservation_id, 10) || null;
    const order_id = parseInt(req.body.order_id, 10) || null;
    const method = String(req.body.method || '').toLowerCase();

    if (!reservation_id && !order_id) {
      return res.status(400).json({ message: 'reservation_id atau order_id wajib diisi' });
    }
    if (!METHODS.includes(method)) {
      return res.status(400).json({ message: `Metode harus salah satu dari: ${METHODS.join(', ')}` });
    }

    await expireStale();

    const isOrder = !reservation_id;
    const found = isOrder
      ? await pool.query(
          'SELECT id, order_code AS code, status, total_amount FROM orders WHERE id = $1 AND user_id = $2',
          [order_id, req.user.id]
        )
      : await pool.query(
          'SELECT id, booking_code AS code, status, total_amount FROM reservations WHERE id = $1 AND user_id = $2',
          [reservation_id, req.user.id]
        );
    if (found.rows.length === 0) {
      return res.status(404).json({ message: isOrder ? 'Pesanan tidak ditemukan' : 'Reservasi tidak ditemukan' });
    }
    const t = found.rows[0];

    if (t.status === 'cancelled') {
      return res.status(400).json({ message: 'Waktu pembayaran habis, silakan buat ulang' });
    }
    if (t.status !== 'pending') {
      return res.status(400).json({ message: `Status ${t.status}, tidak bisa dibayar` });
    }
    if (Number(t.total_amount) <= 0) {
      return res.status(400).json({ message: 'Tidak ada yang perlu dibayar' });
    }

    // Kalau sudah ada pembayaran pending, cukup ganti metodenya
    const col = isOrder ? 'order_id' : 'reservation_id';
    const existing = await pool.query(
      `SELECT id FROM payments WHERE ${col} = $1 AND status = 'pending'`,
      [t.id]
    );
    let result;
    if (existing.rows.length > 0) {
      result = await pool.query(
        'UPDATE payments SET method = $1, amount = $2 WHERE id = $3 RETURNING *',
        [method, t.total_amount, existing.rows[0].id]
      );
    } else {
      result = await pool.query(
        `INSERT INTO payments (${col}, method, amount) VALUES ($1, $2, $3) RETURNING *`,
        [t.id, method, t.total_amount]
      );
    }

    const payment = result.rows[0];
    // Data simulasi untuk ditampilkan di halaman pembayaran
    payment.code = t.code;
    payment.booking_code = t.code;
    payment.qr_payload = method === 'qris' ? `FASTBOOKING|${t.code}|${t.total_amount}` : null;
    res.status(201).json(payment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// "Saya sudah bayar": pembayaran sukses, reservasi atau pesanan menjadi paid
router.post('/:id/confirm', authRequired, async (req, res) => {
  const client = await pool.connect();
  try {
    await expireStale();
    await client.query('BEGIN');

    const p = await client.query('SELECT * FROM payments WHERE id = $1 FOR UPDATE', [req.params.id]);
    if (p.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    }
    const pay = p.rows[0];

    let target;
    let table;
    let code;
    if (pay.reservation_id) {
      table = 'reservations';
      const r = await client.query(
        'SELECT * FROM reservations WHERE id = $1 AND user_id = $2 FOR UPDATE',
        [pay.reservation_id, req.user.id]
      );
      target = r.rows[0];
      code = target && target.booking_code;
    } else if (pay.order_id) {
      table = 'orders';
      const o = await client.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2 FOR UPDATE',
        [pay.order_id, req.user.id]
      );
      target = o.rows[0];
      code = target && target.order_code;
    }
    if (!target) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    }

    if (target.status === 'cancelled') {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Waktu pembayaran habis, silakan buat ulang' });
    }
    if (pay.status !== 'pending' || target.status !== 'pending') {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Pembayaran ini sudah diproses atau tidak bisa dibayar' });
    }

    const updated = await client.query(
      "UPDATE payments SET status = 'success', paid_at = NOW() WHERE id = $1 RETURNING *",
      [pay.id]
    );
    await client.query(`UPDATE ${table} SET status = 'paid' WHERE id = $1`, [target.id]);
    await client.query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [
        req.user.id,
        'Pembayaran berhasil',
        table === 'orders'
          ? `Pembayaran pesanan ${code} berhasil. Pesanan Anda segera diproses.`
          : `Pembayaran reservasi ${code} berhasil. Sampai jumpa di restoran!`,
      ]
    );

    await client.query('COMMIT');
    const payment = updated.rows[0];
    payment.code = code;
    payment.booking_code = code;
    res.json(payment);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// Detail pembayaran
router.get('/:id', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, COALESCE(r.booking_code, o.order_code) AS booking_code
       FROM payments p
       LEFT JOIN reservations r ON r.id = p.reservation_id
       LEFT JOIN orders o ON o.id = p.order_id
       WHERE p.id = $1 AND (r.user_id = $2 OR o.user_id = $2)`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;