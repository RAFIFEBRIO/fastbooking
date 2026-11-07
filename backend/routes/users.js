const express = require('express');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

// Ubah data akun (halaman Akun)
router.put('/me', authRequired, async (req, res) => {
  try {
    const full_name = (req.body.full_name || '').trim();
    const email = (req.body.email || '').trim() || null;
    const address = (req.body.address || '').trim() || null;

    if (!full_name) return res.status(400).json({ message: 'Nama wajib diisi' });
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid' });
    }

    const result = await pool.query(
      'UPDATE users SET full_name = $1, email = $2, address = $3 WHERE id = $4 RETURNING *',
      [full_name, email, address, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'User tidak ditemukan' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;