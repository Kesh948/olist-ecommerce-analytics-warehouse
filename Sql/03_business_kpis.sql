USE olist_dw;

-- Query 3A: Does Late Delivery Destroy Customer Review Scores?
WITH clean_reviews AS (
    -- Deduplicate reviews so each order_id has only its latest review score
    SELECT 
        order_id,
        AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT 
    CASE 
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 
            THEN 'Late Delivery'
        ELSE 'On-Time / Early'
    END AS delivery_status,
    COUNT(o.order_id) AS total_delivered_orders,
    ROUND(COUNT(o.order_id) * 100.0 / SUM(COUNT(o.order_id)) OVER(), 2) AS pct_of_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_actual_days,
    ROUND(AVG(r.avg_review_score), 2) AS avg_review_score
FROM orders o
LEFT JOIN clean_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;


-- Query 3B: Monthly Delivered GMV, Order Volume & Month-over-Month (MoM) Growth
CREATE OR REPLACE VIEW vw_monthly_gmv_growth AS
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(p.payment_value), 2) AS monthly_gmv,
        ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
    FROM orders o
    INNER JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    order_month,
    total_orders,
    monthly_gmv,
    avg_order_value,
    LAG(monthly_gmv) OVER (ORDER BY order_month) AS prev_month_gmv,
    ROUND(
        (monthly_gmv - LAG(monthly_gmv) OVER (ORDER BY order_month)) * 100.0 
        / NULLIF(LAG(monthly_gmv) OVER (ORDER BY order_month), 0), 
    2) AS mom_growth_pct
FROM monthly_revenue
ORDER BY order_month;


-- Query 3C: True Customer Retention & Repeat Purchase Rate
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS lifetime_orders,
        ROUND(SUM(p.payment_value), 2) AS lifetime_spend
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN lifetime_orders = 1 THEN '1 Order (One-Time Buyer)'
        WHEN lifetime_orders = 2 THEN '2 Orders (Repeat Buyer)'
        ELSE '3+ Orders (Loyal VIP)'
    END AS customer_segment,
    COUNT(customer_unique_id) AS total_customers,
    ROUND(COUNT(customer_unique_id) * 100.0 / SUM(COUNT(customer_unique_id)) OVER(), 2) AS pct_of_customers,
    ROUND(SUM(lifetime_spend), 2) AS total_segment_revenue,
    ROUND(AVG(lifetime_spend), 2) AS avg_ltv
FROM customer_orders
GROUP BY customer_segment
ORDER BY total_customers DESC;