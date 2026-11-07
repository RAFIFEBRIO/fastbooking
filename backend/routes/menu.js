const express = require('express');
const pool = require('../db');

const router = express.Router();

// Daftar kategori: /api/menu/categories
router.get('/categories', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM menu_categories ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Daftar menu, bisa difilter: /api/menu?category=Makanan
router.get('/', async (req, res) => {
  try {
    const { category } = req.query;
    let result;
    if (category) {
      result = await pool.query(
        `SELECT m.*, c.name AS category_name
         FROM menu_items m
         JOIN menu_categories c ON c.id = m.category_id
         WHERE m.is_available = TRUE AND c.name = $1
         ORDER BY m.id`,
        [category]
      );
    } else {
      result = await pool.query(
        `SELECT m.*, c.name AS category_name
         FROM menu_items m
         JOIN menu_categories c ON c.id = m.category_id
         WHERE m.is_available = TRUE
         ORDER BY m.category_id, m.id`
      );
    }
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Detail satu menu: /api/menu/1
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT m.*, c.name AS category_name
       FROM menu_items m
       JOIN menu_categories c ON c.id = m.category_id
       WHERE m.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Menu tidak ditemukan' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;