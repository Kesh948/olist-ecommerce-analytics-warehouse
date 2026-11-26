# Executive Strategy Memo: Marketplace Growth, SLA & Funnel Optimization

**To:** Marketplace Leadership & Growth Operations  
**From:** Data Analytics Engineering  
**Subject:** Actionable Recommendations from Olist Warehouse, Funnel & Statistical Audit  

---

## 1. Executive Summary
An integrated audit of Olist's fulfillment warehouse (~100K orders) and B2B seller acquisition funnel (8,000 MQLs) highlights three high-ROI levers: enforcing seller dispatch SLAs to protect customer ratings, reallocating paid B2B acquisition spend, and running a controlled loyalty experiment to lift repeat buyer retention.

---

## 2. Key Insights & Strategic Recommendations

### A. Enforce Seller Dispatch SLAs (Highest Customer Experience ROI)
* **Evidence:** Late deliveries suffer a **-2.02 star drop** compared to on-time orders (`2.27` vs. `4.29` stars; Welch's $t = 100.74, p < 0.0001$).
* **Action:** Use the automated `2_Ops_Late_Sellers_Alert` MIS tab weekly to place sellers exceeding a **20% late-delivery rate** on dispatch probation or require fulfillment-by-Olist warehousing.

### B. Rebalance B2B Paid Search Budget Toward Organic & High-Intent Channels
* **Evidence:** Paid Search (`12.30%` win rate) shows no statistically significant conversion advantage over Organic Search (`11.80%` win rate; $p = 0.6429$).
* **Action:** Cap marginal Paid Search spend on broad B2B keywords and redirect budget toward organic SEO landing pages and SDR follow-up speed for high-GMV seller segments.

### C. Launch a Controlled Post-Delivery Loyalty Voucher Experiment
* **Evidence:** Repeat purchase rates remain low (~3.0% baseline), making customer acquisition expensive.
* **Action:** Execute a randomized 50/50 A/B test offering a second-order incentive voucher to newly delivered buyers, enrolling **3,758 customers per variant** (`7,516` total) to reliably detect a **+1.2 percentage point lift** (`80%` power, $\alpha = 0.05$).