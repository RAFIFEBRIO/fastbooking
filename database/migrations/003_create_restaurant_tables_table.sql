CREATE TABLE restaurant_tables (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  area VARCHAR(20) NOT NULL,
  capacity INT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE
);