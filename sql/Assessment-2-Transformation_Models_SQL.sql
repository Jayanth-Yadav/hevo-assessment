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