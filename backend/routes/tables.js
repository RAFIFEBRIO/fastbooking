const express = require('express');
const pool = require('../db');

const router = express.Router();

// Daftar semua meja, bisa difilter: /api/tables?area=Indoor
router.get('/', async (req, res) => {
  try {
    const { area } = req.query;
    let result;
    if (area) {
      result = await pool.query(
        'SELECT * FROM restaurant_tables WHERE is_active = TRUE AND area = $1 ORDER BY capacity, id',
        [area]
      );
    } else {
      result = await pool.query(
        'SELECT * FROM restaurant_tables WHERE is_active = TRUE ORDER BY area, capacity, id'
      );
    }
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Detail satu meja
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM restaurant_tables WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Meja tidak ditemukan' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;