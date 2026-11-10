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
}

// Buat pembayaran untuk reservasi yang masih pending
router.post('/', authRequired, async (req, res) => {
  try {
    const reservation_id = parseInt(req.body.reservation_id, 10);
    const method = String(req.body.method || '').toLowerCase();

    if (!reservation_id) return res.status(400).json({ message: 'reservation_id wajib diisi' });
    if (!METHODS.includes(method)) {
      return res.status(400).json({ message: `Metode harus salah satu dari: ${METHODS.join(', ')}` });
    }

    await expireStale();
    const reservation = await pool.query(
      'SELECT * FROM reservations WHERE id = $1 AND user_id = $2',
      [reservation_id, req.user.id]
    );
    if (reservation.rows.length === 0) {
      return res.status(404).json({ message: 'Reservasi tidak ditemukan' });
    }
    const r = reservation.rows[0];
    if (r.status === 'cancelled') {
      return res.status(400).json({ message: 'Waktu pembayaran habis, silakan reservasi ulang' });
    }
    if (r.status !== 'pending') {
      return res.status(400).json({ message: `Reservasi berstatus ${r.status}, tidak bisa dibayar` });
    }
    if (Number(r.total_amount) <= 0) {
      return res.status(400).json({ message: 'Reservasi ini tidak memerlukan pembayaran' });
    }

    // Kalau sudah ada pembayaran pending, cukup ganti metodenya
    const existing = await pool.query(
      "SELECT id FROM payments WHERE reservation_id = $1 AND status = 'pending'",
      [reservation_id]
    );
    let result;
    if (existing.rows.length > 0) {
      result = await pool.query(
        'UPDATE payments SET method = $1, amount = $2 WHERE id = $3 RETURNING *',
        [method, r.total_amount, existing.rows[0].id]
      );
    } else {
      result = await pool.query(
        'INSERT INTO payments (reservation_id, method, amount) VALUES ($1, $2, $3) RETURNING *',
        [reservation_id, method, r.total_amount]
      );
    }

    const payment = result.rows[0];
    // Data simulasi untuk ditampilkan di halaman pembayaran
    payment.booking_code = r.booking_code;
    payment.qr_payload = method === 'qris' ? `FASTBOOKING|${r.booking_code}|${r.total_amount}` : null;
    res.status(201).json(payment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// "Saya sudah bayar": pembayaran sukses, reservasi menjadi paid
router.post('/:id/confirm', authRequired, async (req, res) => {
  const client = await pool.connect();
  try {
    await expireStale();
    await client.query('BEGIN');

    const found = await client.query(
      `SELECT p.id, p.reservation_id, p.status AS payment_status,
              r.status AS reservation_status, r.booking_code
       FROM payments p
       JOIN reservations r ON r.id = p.reservation_id
       WHERE p.id = $1 AND r.user_id = $2
       FOR UPDATE OF p, r`,
      [req.params.id, req.user.id]
    );
    if (found.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    }
    const row = found.rows[0];
    if (row.reservation_status === 'cancelled') {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Waktu pembayaran habis, silakan reservasi ulang' });
    }
    if (row.payment_status !== 'pending' || row.reservation_status !== 'pending') {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Pembayaran ini sudah diproses atau reservasi tidak bisa dibayar' });
    }

    const updated = await client.query(
      "UPDATE payments SET status = 'success', paid_at = NOW() WHERE id = $1 RETURNING *",
      [row.id]
    );
    await client.query("UPDATE reservations SET status = 'paid' WHERE id = $1", [row.reservation_id]);
    await client.query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [req.user.id, 'Pembayaran berhasil', `Pembayaran reservasi ${row.booking_code} berhasil. Sampai jumpa di restoran!`]
    );

    await client.query('COMMIT');
    const payment = updated.rows[0];
    payment.booking_code = row.booking_code;
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
      `SELECT p.*, r.booking_code
       FROM payments p
       JOIN reservations r ON r.id = p.reservation_id
       WHERE p.id = $1 AND r.user_id = $2`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;