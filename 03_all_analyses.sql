-- ═══════════════════════════════════════════════════════
-- High level business metrics
-- ═══════════════════════════════════════════════════════

USE olist_db;

-- 1. Total Revenue
SELECT 
    ROUND(SUM(payment_value), 2) AS total_revenue
FROM order_payments;

-- 2. Total Orders by Status
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 3. Monthly Revenue Trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id)                        AS total_orders,
    ROUND(SUM(p.payment_value), 2)                    AS monthly_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 4. Top 10 States by Number of Customers
SELECT 
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC
LIMIT 10;


-- ═══════════════════════════════════════════════════════
--  Delivery time and late order analysis
-- ═══════════════════════════════════════════════════════

-- 1. Average Delivery Time by State
SELECT 
    c.customer_state,
    COUNT(o.order_id)                                                        AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)                      AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date,
                       o.order_delivered_customer_date)), 1)                 AS avg_days_early_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 2. On Time vs Late Delivery
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time'
        ELSE 'Late'
    END                            AS delivery_status,
    COUNT(*)                       AS total_orders,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER(), 2) AS percentage
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- 3. Top 10 Worst States by Late Delivery %
WITH delivery_cte AS (
    SELECT 
        c.customer_state,
        COUNT(*)                                                         AS total_orders,
        SUM(CASE 
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
            END)                                                         AS late_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    total_orders,
    late_orders,
    ROUND(late_orders * 100.0 / total_orders, 2) AS late_percentage
FROM delivery_cte
ORDER BY late_percentage DESC
LIMIT 10;


-- ═══════════════════════════════════════════════════════
-- FILE: Seller ranking and performance metrics
-- ═══════════════════════════════════════════════════════

-- 1. Top 10 Sellers by Revenue
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)        AS total_orders,
    ROUND(SUM(oi.price), 2)            AS total_revenue,
    ROUND(AVG(oi.price), 2)            AS avg_order_value,
    ROUND(AVG(r.review_score), 2)      AS avg_review_score
FROM sellers s
JOIN order_items oi  ON s.seller_id   = oi.seller_id
JOIN orders o        ON oi.order_id   = o.order_id
JOIN order_reviews r ON o.order_id    = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 2. Seller Performance Ranking using Window Functions
WITH seller_stats AS (
    SELECT 
        s.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id)   AS total_orders,
        ROUND(SUM(oi.price), 2)       AS total_revenue,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM sellers s
    JOIN order_items oi  ON s.seller_id = oi.seller_id
    JOIN orders o        ON oi.order_id = o.order_id
    JOIN order_reviews r ON o.order_id  = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.seller_state
)
SELECT 
    seller_id,
    seller_state,
    total_orders,
    total_revenue,
    avg_review_score,
    RANK()   OVER (ORDER BY total_revenue DESC)    AS revenue_rank,
    RANK()   OVER (ORDER BY avg_review_score DESC) AS review_rank,
    NTILE(4) OVER (ORDER BY total_revenue DESC)    AS revenue_quartile
FROM seller_stats
ORDER BY revenue_rank
LIMIT 20;

-- 3. Best Seller per State using PARTITION BY
WITH seller_revenue AS (
    SELECT 
        s.seller_id,
        s.seller_state,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    JOIN orders o       ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.seller_state
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY seller_state
                     ORDER BY total_revenue DESC) AS state_rank
    FROM seller_revenue
)
SELECT 
    seller_id,
    seller_state,
    total_revenue,
    state_rank
FROM ranked
WHERE state_rank = 1
ORDER BY total_revenue DESC;


-- ═══════════════════════════════════════════════════════
-- RFM customer segmentation
-- ═══════════════════════════════════════════════════════

WITH rfm_base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF('2018-09-01', MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id)                              AS frequency,
        ROUND(SUM(p.payment_value), 2)                         AS monetary
    FROM customers c
    JOIN orders o         ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id    = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)     AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal Customer'
            WHEN r_score >= 4 AND f_score <= 2                   THEN 'New Customer'
            WHEN r_score <= 2 AND f_score >= 3                   THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
            ELSE 'Potential Loyalist'
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*)                        AS total_customers,
    ROUND(AVG(recency_days), 1)     AS avg_recency_days,
    ROUND(AVG(frequency), 1)        AS avg_frequency,
    ROUND(AVG(monetary), 2)         AS avg_monetary,
    ROUND(SUM(monetary), 2)         AS total_revenue
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;


-- ═══════════════════════════════════════════════════════
-- Product category revenue and MoM growth
-- ═══════════════════════════════════════════════════════

-- 1. Top 10 Product Categories by Revenue
SELECT 
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'Unknown')  AS category,
    COUNT(DISTINCT oi.order_id)                   AS total_orders,
    ROUND(SUM(oi.price), 2)                       AS total_revenue,
    ROUND(AVG(oi.price), 2)                       AS avg_price,
    ROUND(SUM(oi.freight_value), 2)               AS total_freight
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
LEFT JOIN product_category_translation t
                ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- 2. Freight vs Price Ratio by Category
WITH category_stats AS (
    SELECT 
        COALESCE(t.product_category_name_english,
                 p.product_category_name, 'Unknown') AS category,
        ROUND(AVG(oi.price), 2)                      AS avg_price,
        ROUND(AVG(oi.freight_value), 2)              AS avg_freight
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t
                    ON p.product_category_name = t.product_category_name
    GROUP BY category
    HAVING COUNT(*) > 100
)
SELECT *,
    ROUND(avg_freight * 100.0 / avg_price, 2)                         AS freight_pct_of_price,
    RANK() OVER (ORDER BY avg_freight * 100.0 / avg_price DESC)       AS freight_ratio_rank
FROM category_stats
ORDER BY freight_pct_of_price DESC
LIMIT 10;

-- 3. Month over Month Revenue Growth (Top 5 Categories)
WITH monthly_category AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        COALESCE(t.product_category_name_english,
                 p.product_category_name)                AS category,
        ROUND(SUM(oi.price), 2)                          AS monthly_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o   ON oi.order_id   = o.order_id
    LEFT JOIN product_category_translation t
                    ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY month, category
),
top5_categories AS (
    SELECT category
    FROM monthly_category
    GROUP BY category
    ORDER BY SUM(monthly_revenue) DESC
    LIMIT 5
),
with_lag AS (
    SELECT *,
        LAG(monthly_revenue) OVER (
            PARTITION BY category
            ORDER BY month
        ) AS prev_month_revenue
    FROM monthly_category
    WHERE category IN (SELECT category FROM top5_categories)
)
SELECT 
    month,
    category,
    monthly_revenue,
    prev_month_revenue,
    ROUND((monthly_revenue - prev_month_revenue)
           * 100.0 / prev_month_revenue, 2) AS mom_growth_pct
FROM with_lag
WHERE prev_month_revenue IS NOT NULL
ORDER BY category, month;


-- ═══════════════════════════════════════════════════════
-- Payment type and order value analysis
-- ═══════════════════════════════════════════════════════

-- 1. Revenue by Payment Type
SELECT 
    payment_type,
    COUNT(*)                            AS total_transactions,
    ROUND(SUM(payment_value), 2)        AS total_revenue,
    ROUND(AVG(payment_value), 2)        AS avg_payment,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- 2. PIVOT — Orders by Payment Type per Year
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y') AS year,
    SUM(CASE WHEN p.payment_type = 'credit_card' THEN 1 ELSE 0 END) AS credit_card,
    SUM(CASE WHEN p.payment_type = 'boleto'      THEN 1 ELSE 0 END) AS boleto,
    SUM(CASE WHEN p.payment_type = 'voucher'     THEN 1 ELSE 0 END) AS voucher,
    SUM(CASE WHEN p.payment_type = 'debit_card'  THEN 1 ELSE 0 END) AS debit_card
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY year
ORDER BY year;

-- 3. High Value Orders Analysis
WITH order_values AS (
    SELECT 
        o.order_id,
        c.customer_state,
        p.payment_type,
        p.payment_installments,
        ROUND(SUM(p.payment_value), 2) AS order_value
    FROM orders o
    JOIN customers c      ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id    = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_state,
             p.payment_type, p.payment_installments
)
SELECT 
    CASE 
        WHEN order_value < 100  THEN '0-100'
        WHEN order_value < 500  THEN '100-500'
        WHEN order_value < 1000 THEN '500-1000'
        ELSE '1000+'
    END                                  AS order_value_bucket,
    COUNT(*)                             AS total_orders,
    ROUND(AVG(payment_installments), 1)  AS avg_installments,
    ROUND(SUM(order_value), 2)           AS total_revenue,
    ROUND(COUNT(*) * 100.0 /
          SUM(COUNT(*)) OVER(), 2)       AS pct_of_orders
FROM order_values
GROUP BY order_value_bucket
ORDER BY MIN(order_value);


-- ═══════════════════════════════════════════════════════
-- Customer retention cohort analysis
-- ═══════════════════════════════════════════════════════

WITH first_purchase AS (
    -- Step 1: Find each customer's first purchase month
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    -- Step 2: Get all orders per customer with month
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_data AS (
    -- Step 3: Calculate months since first purchase
    SELECT 
        f.cohort_month,
        co.order_month,
        COUNT(DISTINCT f.customer_unique_id) AS total_customers,
        PERIOD_DIFF(
            REPLACE(co.order_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS months_since_first
    FROM first_purchase f
    JOIN customer_orders co ON f.customer_unique_id = co.customer_unique_id
    GROUP BY f.cohort_month, co.order_month
),
cohort_size AS (
    -- Step 4: Get size of each cohort at month 0
    SELECT 
        cohort_month,
        total_customers AS cohort_total
    FROM cohort_data
    WHERE months_since_first = 0
)
-- Step 5: Calculate retention rate
SELECT 
    cd.cohort_month,
    cs.cohort_total,
    cd.months_since_first,
    cd.total_customers    AS retained_customers,
    ROUND(cd.total_customers * 100.0 / cs.cohort_total, 2) AS retention_rate
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
WHERE cd.cohort_month BETWEEN '2017-01' AND '2018-06'
AND cd.months_since_first BETWEEN 0 AND 6
ORDER BY cd.cohort_month, cd.months_since_first;
