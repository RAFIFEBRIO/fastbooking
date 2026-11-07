   const express = require('express');
   const pool = require('../db');

   const router = express.Router();

   // Daftar promo yang masih berlaku (untuk slider beranda)
   router.get('/', async (req, res) => {
     try {
       const result = await pool.query(
         `SELECT * FROM promos
          WHERE valid_until IS NULL OR valid_until >= CURRENT_DATE
          ORDER BY id`
       );
       res.json(result.rows);
     } catch (err) {
       res.status(500).json({ message: err.message });
     }
   });

   module.exports = router;