CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  order_code VARCHAR(20) UNIQUE NOT NULL,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  table_label VARCHAR(50),
  notes TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  total_amount NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);