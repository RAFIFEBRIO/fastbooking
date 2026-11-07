const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

// Ubah 0812... atau +62812... menjadi 62812...
function normalizePhone(phone) {
  let p = String(phone || '').replace(/\D/g, '');
  if (p.startsWith('0')) p = '62' + p.slice(1);
  return p;
}

function validPhone(p) {
  return /^62\d{9,13}$/.test(p);
}

// Buat OTP 6 digit, berlaku 5 menit
async function createOtp(phone) {
  const code = String(Math.floor(100000 + Math.random() * 900000));
  await pool.query('UPDATE otp_codes SET used = TRUE WHERE phone = $1 AND used = FALSE', [phone]);
  await pool.query(
    `INSERT INTO otp_codes (phone, code, expires_at)
     VALUES ($1, $2, NOW() + INTERVAL '5 minutes')`,
    [phone, code]
  );
  console.log(`[OTP] ${phone} -> ${code}`);
  return code;
}

// 1. Daftar
router.post('/register', async (req, res) => {
  try {
    const full_name = (req.body.full_name || '').trim();
    const phone = normalizePhone(req.body.phone);

    if (!full_name) return res.status(400).json({ message: 'Nama wajib diisi' });
    if (!validPhone(phone)) return res.status(400).json({ message: 'Nomor telepon tidak valid' });

    const existing = await pool.query('SELECT * FROM users WHERE phone = $1', [phone]);
    if (existing.rows.length > 0 && existing.rows[0].is_verified) {
      return res.status(409).json({ message: 'Nomor sudah terdaftar, silakan masuk' });
    }

    if (existing.rows.length > 0) {
      await pool.query('UPDATE users SET full_name = $1 WHERE phone = $2', [full_name, phone]);
    } else {
      await pool.query('INSERT INTO users (full_name, phone) VALUES ($1, $2)', [full_name, phone]);
    }

    const code = await createOtp(phone);
    res.status(201).json({ message: 'OTP dikirim', phone, otp_dev: code });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 2. Verifikasi OTP (dipakai untuk daftar dan masuk)
router.post('/verify-otp', async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const code = String(req.body.code || '').trim();

    const otp = await pool.query(
      `SELECT * FROM otp_codes
       WHERE phone = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY id DESC LIMIT 1`,
      [phone, code]
    );
    if (otp.rows.length === 0) {
      return res.status(400).json({ message: 'Kode OTP salah atau sudah kedaluwarsa' });
    }

    await pool.query('UPDATE otp_codes SET used = TRUE WHERE id = $1', [otp.rows[0].id]);
    const userResult = await pool.query(
      'UPDATE users SET is_verified = TRUE WHERE phone = $1 RETURNING *',
      [phone]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const user = userResult.rows[0];
    const token = jwt.sign({ id: user.id, phone: user.phone }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ message: 'Verifikasi berhasil', token, user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 3. Masuk (kirim OTP ke user yang sudah terdaftar)
router.post('/login', async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    if (!validPhone(phone)) return res.status(400).json({ message: 'Nomor telepon tidak valid' });

    const user = await pool.query('SELECT * FROM users WHERE phone = $1 AND is_verified = TRUE', [phone]);
    if (user.rows.length === 0) {
      return res.status(404).json({ message: 'Nomor belum terdaftar, silakan daftar' });
    }

    const code = await createOtp(phone);
    res.json({ message: 'OTP dikirim', phone, otp_dev: code });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// 4. Data user yang sedang login
router.get('/me', authRequired, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) return res.status(404).json({ message: 'User tidak ditemukan' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;