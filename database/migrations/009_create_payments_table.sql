CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  reservation_id INT REFERENCES reservations(id) ON DELETE CASCADE,
  method VARCHAR(20) NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  paid_at TIMESTAMP
);