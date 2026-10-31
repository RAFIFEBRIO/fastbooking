CREATE TABLE menu_items (
  id SERIAL PRIMARY KEY,
  category_id INT REFERENCES menu_categories(id),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT TRUE
);