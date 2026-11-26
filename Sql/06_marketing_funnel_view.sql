USE olist_dw;

CREATE OR REPLACE VIEW vw_marketing_funnel AS
WITH seller_gmv AS (
    SELECT 
        seller_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(item_price), 2) AS total_gmv
    FROM vw_fact_order_items
    WHERE order_status = 'delivered'
    GROUP BY seller_id
)
SELECT 
    m.mql_id,
    m.first_contact_date,
    DATE_FORMAT(m.first_contact_date, '%Y-%m') AS lead_month,
    m.landing_page_id,
    m.origin AS acquisition_channel,
    CASE WHEN d.mql_id IS NOT NULL THEN 1 ELSE 0 END AS is_closed_won,
    d.seller_id,
    d.sdr_id,
    d.sr_id,
    d.won_date,
    DATEDIFF(d.won_date, m.first_contact_date) AS days_to_close,
    d.business_segment,
    d.lead_type,
    d.lead_behaviour_profile,
    d.business_type,
    COALESCE(sg.total_orders, 0) AS seller_delivered_orders,
    COALESCE(sg.total_gmv, 0) AS seller_delivered_gmv
FROM olist_mql m
LEFT JOIN olist_closed_deals d ON m.mql_id = d.mql_id
LEFT JOIN seller_gmv sg ON d.seller_id = sg.seller_id;


-- Check funnel metrics
SELECT acquisition_channel, COUNT(*) AS leads, SUM(is_closed_won) AS won_deals, ROUND(AVG(is_closed_won)*100, 2) AS win_rate_pct, ROUND(SUM(seller_delivered_gmv), 2) AS live_gmv FROM vw_marketing_funnel GROUP BY acquisition_channel ORDER BY leads DESC;