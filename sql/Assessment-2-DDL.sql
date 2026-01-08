CREATE TABLE customers_raw (customer_id INTEGER, email VARCHAR, phone VARCHAR, country_code VARCHAR, updated_at TIMESTAMP, created_at TIMESTAMP);

CREATE TABLE orders_raw (order_id INTEGER, customer_id INTEGER, product_id VARCHAR, amount DECIMAL(10,2), created_at TIMESTAMP, currency VARCHAR(3));

CREATE TABLE products_raw (product_id VARCHAR PRIMARY KEY, product_name VARCHAR, category VARCHAR, active_flag CHAR(1));

CREATE TABLE country_dim (country_name VARCHAR, iso_code VARCHAR);