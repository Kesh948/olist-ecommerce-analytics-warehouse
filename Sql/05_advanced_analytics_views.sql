USE olist_dw;

-- ============================================================================
-- VIEW 1: RFM Customer Segmentation (vw_customer_rfm)
-- ============================================================================
CREATE OR REPLACE VIEW vw_customer_rfm AS
WITH customer_base AS (
    SELECT 
        c.customer_unique_id,
        MAX(c.state) AS customer_state,
        DATEDIFF('2018-10-17', MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.order_revenue), 2) AS monetary
    FROM vw_fact_orders o
    JOIN vw_dim_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT 
        *,
        -- Lower recency_days = more recent = higher score (5)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        CASE 
            WHEN frequency >= 3 THEN 5
            WHEN frequency = 2 THEN 4
            ELSE 1 
        END AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_base
)
SELECT 
    customer_unique_id,
    customer_state,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    CASE 
        WHEN frequency >= 2 AND r_score >= 4 THEN 'Champions (Repeat & Recent)'
        WHEN frequency >= 2 AND r_score < 4 THEN 'Loyal Repeaters (Needs Re-engagement)'
        WHEN frequency = 1 AND r_score >= 4 AND m_score >= 4 THEN 'Promising High-Value New'
        WHEN frequency = 1 AND r_score <= 2 AND m_score >= 4 THEN 'At-Risk High Spenders'
        WHEN frequency = 1 AND r_score >= 3 THEN 'Recent One-Time Buyers'
        ELSE 'Hibernating One-Time Buyers'
    END AS customer_segment
FROM rfm_scores;


-- ============================================================================
-- VIEW 2: Monthly Cohort Retention Matrix (vw_cohort_retention)
-- ============================================================================
CREATE OR REPLACE VIEW vw_cohort_retention AS
WITH user_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month
    FROM vw_fact_orders o
    JOIN vw_dim_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
first_purchase AS (
    SELECT 
        customer_unique_id,
        MIN(order_month) AS cohort_month
    FROM user_orders
    GROUP BY customer_unique_id
),
cohort_activities AS (
    SELECT 
        f.cohort_month,
        TIMESTAMPDIFF(MONTH, f.cohort_month, u.order_month) AS cohort_index,
        COUNT(DISTINCT u.customer_unique_id) AS active_customers
    FROM first_purchase f
    JOIN user_orders u ON f.customer_unique_id = u.customer_unique_id
    GROUP BY f.cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        active_customers AS cohort_size
    FROM cohort_activities
    WHERE cohort_index = 0
)
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    ca.cohort_index,
    ca.active_customers,
    ROUND((ca.active_customers / cs.cohort_size) * 100, 2) AS retention_rate_pct
FROM cohort_activities ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month >= '2017-01-01';


-- ============================================================================
-- VIEW 3: Data Health & Governance Scorecard (vw_data_health_metrics)
-- ============================================================================

CREATE OR REPLACE VIEW vw_data_health_metrics AS
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(CASE WHEN order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0 END) AS leaked_orders,
    ROUND(SUM(CASE WHEN order_status IN ('canceled', 'unavailable') THEN COALESCE(order_revenue, 0) ELSE 0 END), 2) AS leaked_gmv,
    SUM(CASE WHEN order_status = 'delivered' AND sla_status = 'Not Delivered' THEN 1 ELSE 0 END) AS missing_delivery_ts_count,
    SUM(CASE WHEN order_status = 'delivered' AND (order_revenue IS NULL OR order_revenue = 0) THEN 1 ELSE 0 END) AS zero_revenue_delivered_count,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_review_count,
    ROUND(
        (1 - (
            SUM(CASE 
                WHEN (order_status = 'delivered' AND sla_status = 'Not Delivered') 
                  OR (order_status = 'delivered' AND (order_revenue IS NULL OR order_revenue = 0))
                THEN 1 ELSE 0 
            END) / COUNT(DISTINCT order_id)
        )) * 100, 2
    ) AS data_completeness_pct
FROM vw_fact_orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m');