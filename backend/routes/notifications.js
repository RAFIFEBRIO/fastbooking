const express = require('express');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

// Daftar notifikasi: /api/notifications atau /api/notifications?unread=true
router.get('/', authRequired, async (req, res) => {
  try {
    const onlyUnread = req.query.unread === 'true';
    const result = await pool.query(
      `SELECT * FROM notifications
       WHERE user_id = $1 AND ($2::boolean = FALSE OR is_read = FALSE)
       ORDER BY created_at DESC, id DESC`,
      [req.user.id, onlyUnread]
    );
    const unread = result.rows.filter((n) => !n.is_read).length;
    res.json({ unread_count: unread, notifications: result.rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Tandai semua dibaca (ditulis sebelum /:id/read supaya tidak tertukar)
router.patch('/read-all', authRequired, async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET is_read = TRUE WHERE user_id = $1', [req.user.id]);
    res.json({ message: 'Semua notifikasi ditandai sudah dibaca' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Tandai satu notifikasi dibaca
router.patch('/:id/read', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;