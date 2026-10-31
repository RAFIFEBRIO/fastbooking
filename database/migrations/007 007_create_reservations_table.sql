CREATE TABLE reservations (
  id SERIAL PRIMARY KEY,
  booking_code VARCHAR(20) UNIQUE NOT NULL,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  table_id INT REFERENCES restaurant_tables(id),
  reservation_date DATE NOT NULL,
  reservation_time TIME NOT NULL,
  guest_count INT NOT NULL,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  total_amount NUMERIC(12,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);