CREATE TABLE promos (
  id SERIAL PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  description TEXT,
  discount_percent INT,
  valid_until DATE
);