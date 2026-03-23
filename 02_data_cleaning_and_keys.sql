-- ═══════════════════════════════════════════════════════
-- FILE: 02_data_cleaning_and_keys.sql
-- DESC: Clean dirty data, add Primary Keys and Foreign Keys
-- ═══════════════════════════════════════════════════════

USE olist_db;

-- ─────────────────────────────────────────────
-- STEP 1: DATA CLEANING
-- MySQL 8.0 strict mode rejects 0000-00-00 00:00:00
-- These are empty dates from CSV loaded as zero dates
-- Fix: replace with NULL
-- ─────────────────────────────────────────────

SET sql_mode = '';

UPDATE orders SET order_approved_at = NULL
    WHERE order_approved_at = '0000-00-00 00:00:00';
-- 160 rows fixed

UPDATE orders SET order_delivered_carrier_date = NULL
    WHERE order_delivered_carrier_date = '0000-00-00 00:00:00';
-- 1783 rows fixed

UPDATE orders SET order_delivered_customer_date = NULL
    WHERE order_delivered_customer_date = '0000-00-00 00:00:00';
-- 2965 rows fixed

UPDATE orders SET order_estimated_delivery_date = NULL
    WHERE order_estimated_delivery_date = '0000-00-00 00:00:00';
-- 0 rows (already clean)

-- ─────────────────────────────────────────────
-- STEP 2: FIX MISSING REFERENCE DATA
-- 3 product categories exist in products table
-- but are missing from product_category_translation
-- Fix: insert them manually
-- ─────────────────────────────────────────────

INSERT INTO product_category_translation VALUES
('pc_gamer', 'pc_gamer'),
('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_processors'),
('', '');

-- ─────────────────────────────────────────────
-- STEP 3: PRIMARY KEYS
-- ─────────────────────────────────────────────

ALTER TABLE customers
    ADD PRIMARY KEY (customer_id);

ALTER TABLE sellers
    ADD PRIMARY KEY (seller_id);

ALTER TABLE products
    ADD PRIMARY KEY (product_id);

ALTER TABLE orders
    ADD PRIMARY KEY (order_id);

ALTER TABLE product_category_translation
    ADD PRIMARY KEY (product_category_name);

-- order_items has no single unique column
-- composite PK used instead
ALTER TABLE order_items
    ADD PRIMARY KEY (order_id, order_item_id);

-- ─────────────────────────────────────────────
-- STEP 4: FOREIGN KEYS
-- ─────────────────────────────────────────────

-- orders → customers
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- order_items → orders
ALTER TABLE order_items
    ADD CONSTRAINT fk_items_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- order_items → products
ALTER TABLE order_items
    ADD CONSTRAINT fk_items_products
    FOREIGN KEY (product_id) REFERENCES products(product_id);

-- order_items → sellers
ALTER TABLE order_items
    ADD CONSTRAINT fk_items_sellers
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

-- order_payments → orders
ALTER TABLE order_payments
    ADD CONSTRAINT fk_payments_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- order_reviews → orders
ALTER TABLE order_reviews
    ADD CONSTRAINT fk_reviews_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- products → product_category_translation
ALTER TABLE products
    ADD CONSTRAINT fk_products_category
    FOREIGN KEY (product_category_name)
    REFERENCES product_category_translation(product_category_name);

-- ─────────────────────────────────────────────
-- VERIFY ALL FOREIGN KEYS
-- ─────────────────────────────────────────────
SELECT
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'olist_db'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
