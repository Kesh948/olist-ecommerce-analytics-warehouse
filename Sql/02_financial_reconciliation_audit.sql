USE olist_dw;

-- Reconcile Billed Order Value (Items + Freight) vs. Collected Payments
WITH item_totals AS (
    SELECT 
        order_id,
        COUNT(order_item_id) AS total_items,
        ROUND(SUM(price), 2) AS total_product_value,
        ROUND(SUM(freight_value), 2) AS total_freight_value,
        ROUND(SUM(price + freight_value), 2) AS expected_order_total
    FROM order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT 
        order_id,
        COUNT(payment_sequential) AS payment_installments,
        ROUND(SUM(payment_value), 2) AS actual_paid_total
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    o.order_status,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN i.order_id IS NULL THEN 1 ELSE 0 END) AS missing_items_count,
    SUM(CASE WHEN p.order_id IS NULL THEN 1 ELSE 0 END) AS missing_payment_count,
    SUM(CASE 
        WHEN ABS(COALESCE(i.expected_order_total, 0) - COALESCE(p.actual_paid_total, 0)) > 0.05 
        THEN 1 ELSE 0 
    END) AS amount_mismatch_count,
    ROUND(SUM(COALESCE(p.actual_paid_total, 0)), 2) AS total_collected_revenue
FROM orders o
LEFT JOIN item_totals i ON o.order_id = i.order_id
LEFT JOIN payment_totals p ON o.order_id = p.order_id
GROUP BY o.order_status
ORDER BY total_orders DESC;