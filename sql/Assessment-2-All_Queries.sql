--Assessment 2 - DDL

CREATE TABLE customers_raw (customer_id INTEGER, email VARCHAR, phone VARCHAR, country_code VARCHAR, updated_at TIMESTAMP, created_at TIMESTAMP);

CREATE TABLE orders_raw (order_id INTEGER, customer_id INTEGER, product_id VARCHAR, amount DECIMAL(10,2), created_at TIMESTAMP, currency VARCHAR(3));

CREATE TABLE products_raw (product_id VARCHAR PRIMARY KEY, product_name VARCHAR, category VARCHAR, active_flag CHAR(1));

CREATE TABLE country_dim (country_name VARCHAR, iso_code VARCHAR);


-- Assessment 2 DML

INSERT INTO customers_raw VALUES (101,'John@example.com','111-222-3333','US','2025-07-01 10:15:00','2025-01-01 08:00:00'),(101,'john.d@example.com','(111)2223333','usa','2025-07-03 14:25:00','2025-01-01 08:00:00'),(102,'alice@example.com',NULL,'UnitedStates','2025-07-01 09:10:00',NULL),(103,'michael@abc.com','9998887777',NULL,'2025-07-02 12:45:00','2025-03-01 10:00:00'),(104,'bob@xyz.com',NULL,'IND','2025-07-05 15:00:00','2025-03-10 09:30:00'),(104,'bob@xyz.com',NULL,'India','2025-07-06 18:00:00','2025-03-10 09:30:00'),(106,'duplicate@email.com','1234567890','SINGAPORE','2025-07-01 08:00:00','2025-04-01 11:45:00'),(106,'duplicate@email.com','123-456-7890','SG','2025-07-10 12:00:00','2025-04-01 11:45:00'),(108,NULL,NULL,NULL,NULL,NULL);

INSERT INTO orders_raw VALUES (5001,101,'P01',120.00,'2025-07-10 09:00:00','USD'),(5002,102,'P02',80.50,'2025-07-10 09:05:00','usd'),(5003,103,NULL,200.00,'2025-07-10 09:15:00','INR'),(5004,105,'P99',NULL,'2025-07-10 09:20:00',NULL),(5002,102,'P02',80.50,'2025-07-10 09:05:00','USD'),(5005,106,'P03',-50.00,'2025-07-10 09:25:00','SGD'),(5006,107,NULL,300.00,'2025-07-11 10:00:00','usd'),(5007,108,'P04',500.00,'2025-07-11 10:15:00','EUR');

INSERT INTO products_raw VALUES ('P01','keyboard','hardware','Y'),('P02','MOUSE','Hardware','Y'),('P03','Monitor','Hardware','N'),('P04','Premium Cable','Accessory','Y');

INSERT INTO country_dim VALUES ('United States','US'),('India','IN'),('Singapore','SG'),('Unknown',NULL);



-- 1) Cleaned Customer Model SQL

SELECT customer_id,latest_updated, cleaned_email, cleaned_phone, cleaned_country_code FROM (
SELECT customer_id, COALESCE(updated_at, '1900-01-01') AS latest_updated, LOWER(TRIM(email)),
  CASE 
    WHEN customer_id IS NULL AND email IS NULL AND phone IS NULL AND country_code IS NULL 
    THEN 'Invalid Customer'
    WHEN email IS NULL OR TRIM(email) = '' THEN 'Invalid Customer'
    ELSE LOWER(TRIM(email))
  END AS cleaned_email,
  CASE
    WHEN PHONE IS NULL OR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '')) < 10 THEN 'Unknown'
    WHEN UPPER(TRIM(country_code)) IN ('IN', 'INDIA', 'IND') THEN
    CONCAT('+91', REGEXP_REPLACE(phone, '[^0-9]', ''))
    WHEN UPPER(TRIM(country_code)) IN ('US', 'USA', 'UNITEDSTATES') THEN 
    CONCAT('+1', REGEXP_REPLACE(phone, '[^0-9]', ''))
    WHEN UPPER(TRIM(country_code)) IN ('SG', 'SINGAPORE') THEN 
    CONCAT('+65', REGEXP_REPLACE(phone, '[^0-9]', ''))
    ELSE REGEXP_REPLACE(phone, '[^0-9]', '')
    END AS cleaned_phone, 
  CASE 
    WHEN UPPER(TRIM(country_code)) IN ('USA', 'UNITEDSTATES','US') THEN 'US'
    WHEN UPPER(TRIM(country_code)) IN ('IND','IN', 'INDIA') THEN 'IN'
    WHEN UPPER(TRIM(country_code)) IN ('SINGAPORE', 'SG') THEN 'SG'
    ELSE UPPER(TRIM(country_code)) 
  END AS cleaned_country_code,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) AS rowNum
  FROM customers_raw
) WHERE rowNum = 1


-- 2) Clean Orders Model SQL

SELECT order_id, customer_id, product_id, cleaned_amount, created_at, cleaned_currency, amount_in_usd FROM (
  SELECT order_id, customer_id, product_id,
  CASE WHEN amount < 0 OR amount IS NULL THEN 0 ELSE amount END AS cleaned_amount, created_at,
  UPPER(currency) AS cleaned_currency,
  CASE 
    WHEN UPPER(currency) = 'USD' THEN cleaned_amount
    WHEN UPPER(currency) = 'EUR' THEN cleaned_amount * 1.1
    WHEN UPPER(currency) = 'INR' THEN cleaned_amount * 0.0111
    WHEN UPPER(currency) = 'SGD' THEN cleaned_amount * 0.78
    ELSE cleaned_amount
  END AS amount_in_usd,
  ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at) AS rowNum
FROM orders_raw)
WHERE rowNum = 1


-- 3) Clean Products Model SQL

SELECT product_id, INITCAP(TRIM(product_name)) AS cleaned_product_name, INITCAP(TRIM(category)) AS cleaned_category,
CASE
  WHEN active_flag = 'N' THEN 'Discontinued Product'
  ELSE active_flag
 END as product_status
FROM products_raw


-- 4) Final Resultant Model SQL

select o.order_id, o.customer_id, o.product_id, o.cleaned_amount amount, o.cleaned_currency currency, o.amount_in_usd, o.created_at,
coalesce(p.cleaned_category, 'unknown category') category, coalesce(c.cleaned_country_code, 'unknown country') country
from cleaned_orders o
left join cleaned_customers c on o.customer_id = c.customer_id
left join cleaned_products p on o.product_id = p.product_id


-- Assessment 2 Validation

SELECT * FROM CLEANED_CUSTOMERS;
SELECT * FROM CLEANED_ORDERS;
SELECT * FROM CLEANED_PRODUCTS;
SELECT * FROM CLEANED_FINAL_RESULT;