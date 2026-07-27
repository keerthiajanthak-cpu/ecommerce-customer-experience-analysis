-- =====================================================
-- 00 Database Setup Note
-- Purpose: Original imported CSV table names were renamed
-- for cleaner SQL analysis.
-- =====================================================

-- olist_customers_dataset              -> customers
-- olist_orders_dataset                 -> orders
-- olist_order_items_dataset            -> order_items
-- olist_order_payments_dataset         -> payments
-- olist_products_dataset               -> products
-- olist_sellers_dataset                -> sellers
-- product_category_name_translation    -> category_translation

-- 00B Performance Optimisation
-- Purpose: Create indexes on join and filter columns to improve query speed

-- CREATE INDEX idx_orders_order_id ON orders(order_id);
-- CREATE INDEX idx_orders_status ON orders(order_status);
-- CREATE INDEX idx_order_items_order_id ON order_items(order_id);
-- CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
-- CREATE INDEX idx_sellers_seller_id ON sellers(seller_id);

CREATE DATABASE IF NOT EXISTS ecommerce_analysis;

USE ecommerce_analysis;

-- 01 Data Understanding: Table Structure Checks
-- Purpose: Review column names and data types before analysis

DESCRIBE customers;
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE payments;
DESCRIBE products;
DESCRIBE sellers;
DESCRIBE category_translation;

-- 02 Data Quality Check
-- Purpose: Check whether all imported tables loaded correctly

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;

-- 03 Monthly Revenue Analysis
-- Purpose: Analyse monthly order volume and revenue trend
-- Business Question: How many orders were placed each month, and how much revenue was generated?

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

-- 04 Order Status Analysis
-- Purpose: Understand how many orders are delivered, cancelled,shipped, invoiced, unavailable, or still processing.
-- Business Question: What is the distribution of order statuses in the dataset?

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 05 Delivery Performance Analysis
-- Purpose: Measure average delivery time and late delivery rate
-- Business Question: How long do orders take to arrive, and what percentage are delivered late?

SELECT
    DATE_FORMAT(STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'), '%Y-%m') AS order_month,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s')
    )), 2) AS avg_delivery_days,
    ROUND(
        SUM(CASE 
            WHEN STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
                 STR_TO_DATE(NULLIF(order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
            THEN 1 ELSE 0 
        END) * 100.0 / COUNT(*), 
    2) AS late_delivery_rate_percent
FROM orders
WHERE order_status = 'delivered'
  AND NULLIF(order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(order_estimated_delivery_date, '') IS NOT NULL
  AND NULLIF(order_purchase_timestamp, '') IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- 06 Late Delivery by Customer State
-- Purpose: Identify which customer states have the highest late delivery rate
-- Business Question: Which customer states experience the most delivery delays?

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s')
    )), 2) AS avg_delivery_days,
    ROUND(
        SUM(CASE
            WHEN STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
                 STR_TO_DATE(NULLIF(o.order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*),
    2) AS late_delivery_rate_percent
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL
  AND NULLIF(o.order_purchase_timestamp, '') IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_rate_percent DESC;

-- 06B Late Delivery by Customer State - High Volume States
-- Purpose: Focus on states with enough order volume for reliable comparison
-- Business Question: Among higher-volume states, which states have the highest late delivery rate?

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s')
    )), 2) AS avg_delivery_days,
    ROUND(
        SUM(CASE
            WHEN STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
                 STR_TO_DATE(NULLIF(o.order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*),
    2) AS late_delivery_rate_percent
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL
  AND NULLIF(o.order_purchase_timestamp, '') IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 1000
ORDER BY late_delivery_rate_percent DESC;

-- 07 Product Category Revenue Analysis
-- Purpose: Identify which product categories generate the most revenue
-- Business Question: Which product categories contribute the most to total revenue?

SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY product_category
ORDER BY total_revenue DESC
LIMIT 15;

-- 08 Seller Performance Analysis
-- Purpose: Identify top-performing sellers by revenue and order volume
-- Business Question: Which sellers generate the highest total revenue?

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_state
ORDER BY total_revenue DESC
LIMIT 15;

-- 09 Seller Delivery Performance Analysis
-- Purpose: Identify sellers with higher delivery delay risk
-- Business Question: Which sellers have the highest late delivery rates?

WITH seller_orders AS (
    SELECT DISTINCT
        oi.seller_id,
        o.order_id,
        DATEDIFF(
            STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s')
        ) AS delivery_days,
        CASE
            WHEN STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
                 STR_TO_DATE(NULLIF(o.order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
            THEN 1 ELSE 0
        END AS is_late
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
      AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL
      AND NULLIF(o.order_purchase_timestamp, '') IS NOT NULL
)

SELECT
    so.seller_id,
    s.seller_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(so.delivery_days), 2) AS avg_delivery_days,
    ROUND(SUM(so.is_late) * 100.0 / COUNT(*), 2) AS late_delivery_rate_percent
FROM seller_orders so
JOIN sellers s
    ON so.seller_id = s.seller_id
GROUP BY
    so.seller_id,
    s.seller_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_rate_percent DESC
LIMIT 15;

-- 10 Product Category Delivery Performance
-- Purpose: Identify product categories with higher delivery delay risk
-- Business Question: Which product categories have the highest late delivery rates?

WITH category_orders AS (
    SELECT DISTINCT
        o.order_id,
        COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
        DATEDIFF(
            STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s')
        ) AS delivery_days,
        CASE
            WHEN STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
                 STR_TO_DATE(NULLIF(o.order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
            THEN 1 ELSE 0
        END AS is_late
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
      AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
      AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL
      AND NULLIF(o.order_purchase_timestamp, '') IS NOT NULL
)

SELECT
    product_category,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(SUM(is_late) * 100.0 / COUNT(*), 2) AS late_delivery_rate_percent
FROM category_orders
GROUP BY product_category
HAVING COUNT(*) >= 500
ORDER BY late_delivery_rate_percent DESC
LIMIT 15;


-- 11 Customer State Revenue Analysis
-- Purpose: Identify which customer states generate the most revenue
-- Business Question: Which customer locations contribute the most to total revenue?

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_revenue_per_order
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 12 Payment Type Analysis
-- Purpose: Understand customer payment behaviour
-- Business Question: Which payment methods are most used and generate the most payment value?

SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_payment_records,
    ROUND(SUM(p.payment_value), 2) AS total_payment_value,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY total_payment_value DESC;

-- 13 Final Dashboard Dataset
-- Purpose: Create a combined dataset for Power BI dashboard
-- Business Question:
-- Can we create one clean table to analyse revenue, delivery performance,
-- customer location, seller location, product category, and payment type?

SELECT
    o.order_id,
    DATE_FORMAT(STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s'), '%Y-%m') AS order_month,
    c.customer_state,
    s.seller_state,
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
    pay.payment_type,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS total_revenue,
    DATEDIFF(
        STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(NULLIF(o.order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s')
    ) AS delivery_days,
    CASE
        WHEN STR_TO_DATE(NULLIF(o.order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s') >
             STR_TO_DATE(NULLIF(o.order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
        THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN sellers s
    ON oi.seller_id = s.seller_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
LEFT JOIN payments pay
    ON o.order_id = pay.order_id
WHERE o.order_status = 'delivered'
  AND NULLIF(o.order_purchase_timestamp, '') IS NOT NULL
  AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL;
