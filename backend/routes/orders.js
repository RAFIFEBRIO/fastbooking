const express = require('express');
const pool = require('../db');
const authRequired = require('../middleware/auth');

const router = express.Router();

const HOLD_MINUTES = 15; // batas waktu pembayaran
const FEE_RATE = 0.15; // pajak 10% + layanan 5%

// Pesanan pending yang melewati batas waktu otomatis dibatalkan
async function expireStale(db = pool) {
  await db.query(
    `UPDATE orders SET status = 'cancelled'
     WHERE status = 'pending'
       AND created_at < LOCALTIMESTAMP - INTERVAL '${HOLD_MINUTES} minutes'`
  );
}

const SELECT_ORDER = `
  SELECT o.id, o.order_code, o.table_label, o.notes, o.status, o.total_amount, o.created_at,
         GREATEST(0, EXTRACT(EPOCH FROM (o.created_at + INTERVAL '${HOLD_MINUTES} minutes' - LOCALTIMESTAMP))::int) AS expires_in
  FROM orders o`;

async function getOrderDetail(id, userId) {
  const o = await pool.query(SELECT_ORDER + ' WHERE o.id = $1 AND o.user_id = $2', [id, userId]);
  if (o.rows.length === 0) return null;
  const items = await pool.query(
    `SELECT oi.menu_item_id, m.name, m.image_url, c.name AS category_name,
            oi.quantity, oi.price, oi.note
     FROM order_items oi
     JOIN menu_items m ON m.id = oi.menu_item_id
     JOIN menu_categories c ON c.id = m.category_id
     WHERE oi.order_id = $1
     ORDER BY oi.id`,
    [id]
  );
  const subtotal = items.rows.reduce((sum, i) => sum + Number(i.price) * i.quantity, 0);
  const total = Number(o.rows[0].total_amount);
  return { ...o.rows[0], items: items.rows, subtotal, fee: total - subtotal };
}

function makeOrderCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'OD';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

// Buat pesanan datang langsung
router.post('/', authRequired, async (req, res) => {
  const items = Array.isArray(req.body.items) ? req.body.items : [];
  const table_label = String(req.body.table_label || '').trim().slice(0, 50) || null;
  const notes = String(req.body.notes || '').trim().slice(0, 200) || null;

  if (items.length === 0) {
    return res.status(400).json({ message: 'Pesanan harus berisi minimal satu menu' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

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
      lines.push({
        menu_item_id: menu.rows[0].id,
        quantity: qty,
        price: Number(menu.rows[0].price),
        note: String(item.note || '').trim().slice(0, 200) || null,
      });
    }
    const subtotal = lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
    const total = subtotal + Math.round(subtotal * FEE_RATE);

    const code = makeOrderCode();
    const inserted = await client.query(
      `INSERT INTO orders (order_code, user_id, table_label, notes, total_amount)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id`,
      [code, req.user.id, table_label, notes, total]
    );
    const orderId = inserted.rows[0].id;

    for (const line of lines) {
      await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, quantity, price, note)
         VALUES ($1, $2, $3, $4, $5)`,
        [orderId, line.menu_item_id, line.quantity, line.price, line.note]
      );
    }

    await client.query(
      'INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)',
      [req.user.id, 'Pesanan dibuat', `Pesanan ${code} menunggu pembayaran.`]
    );

    await client.query('COMMIT');
    const detail = await getOrderDetail(orderId, req.user.id);
    res.status(201).json(detail);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ message: err.message });
  } finally {
    client.release();
  }
});

// Riwayat pesanan user
router.get('/', authRequired, async (req, res) => {
  try {
    await expireStale();
    const result = await pool.query(
      SELECT_ORDER + ' WHERE o.user_id = $1 ORDER BY o.created_at DESC',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Batalkan pesanan (hanya yang masih pending)
router.patch('/:id/cancel', authRequired, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE orders SET status = 'cancelled'
       WHERE id = $1 AND user_id = $2 AND status = 'pending'
       RETURNING id, order_code`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Pesanan tidak ditemukan atau tidak bisa dibatalkan' });
    }
    const detail = await getOrderDetail(req.params.id, req.user.id);
    res.json(detail);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Detail satu pesanan
router.get('/:id', authRequired, async (req, res) => {
  try {
    await expireStale();
    const detail = await getOrderDetail(req.params.id, req.user.id);
    if (!detail) return res.status(404).json({ message: 'Pesanan tidak ditemukan' });
    res.json(detail);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;