-- ═══════════════════════════════════════════════════════
-- FILE: 01_create_tables.sql
-- DESC: Create all 9 tables for Olist E-Commerce Database
-- ═══════════════════════════════════════════════════════

SET GLOBAL local_infile = 1;

CREATE DATABASE IF NOT EXISTS olist_db;
USE olist_db;

-- ─────────────────────────────────────────────
-- 1. CUSTOMERS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(50),
    customer_state VARCHAR(5)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 2. SELLERS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state VARCHAR(5)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 3. PRODUCTS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 4. ORDERS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 5. ORDER ITEMS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 6. ORDER PAYMENTS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 7. ORDER REVIEWS
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 8. GEOLOCATION
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS geolocation;
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(18,15),
    geolocation_lng DECIMAL(18,15),
    geolocation_city VARCHAR(50),
    geolocation_state VARCHAR(5)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- 9. PRODUCT CATEGORY TRANSLATION
-- ─────────────────────────────────────────────
DROP TABLE IF EXISTS product_category_translation;
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
LOAD DATA LOCAL INFILE 'C:/Ramiz/Projects/Sql project/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ─────────────────────────────────────────────
-- VERIFY ROW COUNTS
-- ─────────────────────────────────────────────
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers UNION ALL
SELECT 'products', COUNT(*) FROM products UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;
