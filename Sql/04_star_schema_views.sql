USE olist_dw;

-- 1. Dimension: Customers
CREATE OR REPLACE VIEW vw_dim_customers AS
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code_prefix,
    customer_city AS city,
    customer_state AS state
FROM customers;

-- 2. Dimension: Products (With English Category Names & Null Handling)
CREATE OR REPLACE VIEW vw_dim_products AS
SELECT 
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category_english,
    p.product_weight_g AS weight_g,
    p.product_length_cm AS length_cm,
    p.product_height_cm AS height_cm,
    p.product_width_cm AS width_cm
FROM products p
LEFT JOIN category_translation t 
    ON p.product_category_name = t.product_category_name;

-- 3. Dimension: Sellers
CREATE OR REPLACE VIEW vw_dim_sellers AS
SELECT 
    seller_id,
    seller_zip_code_prefix AS zip_code_prefix,
    seller_city AS city,
    seller_state AS state
FROM sellers;


-- 4. Fact: Orders (Order Grain = 1 row per order_id, zero fan-out duplication)
CREATE OR REPLACE VIEW vw_fact_orders AS
WITH payment_agg AS (
    SELECT 
        order_id,
        ROUND(SUM(payment_value), 2) AS total_paid,
        MAX(payment_type) AS primary_payment_type,
        MAX(payment_installments) AS max_installments
    FROM order_payments
    GROUP BY order_id
),
review_agg AS (
    SELECT 
        order_id,
        ROUND(AVG(review_score), 2) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    DATE(o.order_purchase_timestamp) AS order_date,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    COALESCE(p.total_paid, 0) AS order_revenue,
    COALESCE(p.primary_payment_type, 'unknown') AS payment_type,
    COALESCE(p.max_installments, 1) AS installments,
    r.review_score,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS actual_delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
    CASE 
        WHEN o.order_status <> 'delivered' OR o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN 'Late'
        ELSE 'On-Time'
    END AS sla_status
FROM orders o
LEFT JOIN payment_agg p ON o.order_id = p.order_id
LEFT JOIN review_agg r ON o.order_id = r.order_id;

-- 5. Fact: Order Items (Line-Item Grain = 1 row per item sold)
CREATE OR REPLACE VIEW vw_fact_order_items AS
SELECT 
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,
    o.order_status,
    DATE(o.order_purchase_timestamp) AS order_date,
    ROUND(oi.price, 2) AS item_price,
    ROUND(oi.freight_value, 2) AS freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS total_line_amount,
    CASE 
        WHEN o.order_delivered_carrier_date > oi.shipping_limit_date THEN 'Late Dispatch'
        ELSE 'On-Time Dispatch'
    END AS seller_dispatch_sla
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id;


USE olist_dw;

SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue), 2) AS total_revenue
FROM vw_fact_orders
GROUP BY order_status
ORDER BY total_orders DESC;