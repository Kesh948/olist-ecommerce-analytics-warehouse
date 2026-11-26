---

#### 2. `docs/DATA_DICTIONARY_AND_SOP.md`
```markdown
# Data Dictionary & Governance Standard Operating Procedure (SOP)

## 1. Semantic Warehouse Views (`olist_dw`)

| View Name | Grain | Primary Keys / Dimensions | Core Metrics & Business Logic |
| :--- | :--- | :--- | :--- |
| `vw_fact_orders` | 1 row per `order_id` | `order_id`, `customer_id`, `order_date` | `order_revenue`, `review_score`, `sla_status` (`On-Time`, `Late`, `Not Delivered`) |
| `vw_customer_rfm` | 1 row per `customer_unique_id` | `customer_unique_id`, `customer_state` | `recency_days`, `frequency`, `monetary`, `NTILE(5)` R/F/M scores, `customer_segment` |
| `vw_cohort_retention` | 1 row per `cohort_month` × `cohort_index` | `cohort_month`, `cohort_index` (0–12+) | `active_customers`, `cohort_size`, `retention_rate_pct` |
| `vw_marketing_funnel` | 1 row per `mql_id` | `mql_id`, `seller_id`, `acquisition_channel` | `is_closed_won`, `days_to_close`, `business_segment`, `seller_delivered_gmv` |
| `vw_data_health_metrics` | 1 row per `order_month` | `order_month` (`YYYY-MM`) | `total_orders`, `leaked_orders`, `leaked_gmv`, `data_completeness_pct` |

---

## 2. Data Governance & MIS Operational SOP

* **Ingestion & Schema Validation:** Raw CSV files are validated for primary-key uniqueness (`order_id`, `mql_id`) and normalized for null categorical fields (`origin`, `business_segment`) prior to MySQL loading.
* **SLA & Leakage Monitoring:** `vw_data_health_metrics` audits canceled/unavailable GMV leakage and missing delivery timestamps on delivered orders. Any month dropping below **98.0% completeness** triggers an ETL source audit.
* **Automated Weekly MIS Cadence:** `07_automated_mis_report.py` runs on a scheduled batch cadence to distribute exception lists (`>=20%` late-delivery sellers and high-value RFM win-back targets) to Operations and CRM teams.