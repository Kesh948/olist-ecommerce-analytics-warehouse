# Olist E-Commerce End-to-End Analytics Warehouse & BI Suite

An end-to-end **Data Analytics & Business Intelligence** solution built on the Brazilian Olist E-Commerce and Marketing Funnel datasets (~100K orders, 8,000 MQLs). Engineered with a **MySQL Star Schema**, **automated Python ETL & statistical hypothesis testing**, **scheduled Excel MIS reporting**, and a **3-page Power BI Executive Dashboard**.

---

## Architecture & Data Lifecycle

```text
[Kaggle Raw CSVs (E-Commerce + MQL Funnel)]
                     │
                     ▼  (Python: pandas + SQLAlchemy ETL)
       [MySQL Warehouse: olist_dw]
        ├── Star Schema (vw_fact_orders, vw_fact_order_items, Dimensions)
        └── Analytical Semantic Views:
             ├── vw_customer_rfm (NTILE 1–5 Segmentation)
             ├── vw_cohort_retention (Monthly Acquisition Matrix)
             ├── vw_marketing_funnel (B2B MQL → Closed Deal → B2C GMV Bridge)
             └── vw_data_health_metrics (SLA & Revenue Leakage Governance)
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
[Power BI Dashboard]     [Python Analytics & MIS]
 • Executive Command      • Statistical A/B Testing (SciPy/Statsmodels)
 • Retention & Funnel     • Automated Multi-Tab Excel MIS Pack (XlsxWriter)
 • Data Health Scorecard