CREATE TABLE customers (
  id INTEGER PRIMARY KEY, 
  first_name VARCHAR(100), 
  last_name VARCHAR(100), 
  email VARCHAR(255), 
  address JSONB 
);  

CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  status VARCHAR(50)
);  

CREATE TABLE feedback (
  id INTEGER PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  rating INTEGER,
  comments TEXT
);


ALTER TABLE feedback ADD CONSTRAINT feedback_order_id_key UNIQUE(order_id);