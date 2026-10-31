CREATE TABLE reservation_items (
  id SERIAL PRIMARY KEY,
  reservation_id INT REFERENCES reservations(id) ON DELETE CASCADE,
  menu_item_id INT REFERENCES menu_items(id),
  quantity INT NOT NULL,
  price NUMERIC(12,2) NOT NULL
);