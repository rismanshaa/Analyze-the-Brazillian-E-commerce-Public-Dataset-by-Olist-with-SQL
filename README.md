# Brazilian E-Commerce Analysis (Olist Dataset)

An analytical study of sales performance, delivery logistics, and customer satisfaction across the Olist marketplace network, conducted entirely in SQL against the publicly available [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), with results visualized in Power BI.

License: MIT

## Table of Contents

- [Background](#background)
- [Problem Statement](#problem-statement)
- [Dataset Overview](#dataset-overview)
- [Tools](#tools)
- [Methodology](#methodology)
- [Results and Discussion](#results-and-discussion)
- [Key Finding: The RR Correlation](#key-finding-the-rr-correlation)
- [Limitations](#limitations)
- [Conclusion and Recommendations](#conclusion-and-recommendations)
- [Repository Structure](#repository-structure)
- [How to Reproduce](#how-to-reproduce)
- [Author](#author)
- [License](#license)

## Background

Olist operates as a marketplace integrator: small and medium-sized Brazilian retailers list products through Olist, which in turn distributes those listings across major e-commerce channels and coordinates the logistics and post-purchase experience under a single contract. This structure means Olist sits at the intersection of three forces that jointly determine whether a transaction becomes a satisfied, repeat customer rather than a one-off sale: the volume and mix of what is being sold, the reliability of physical delivery, and the customer's resulting perception of the experience.

This project analyzes those three forces directly, using approximately 100,000 real, anonymized orders placed between 2016 and 2018. Rather than working from a pre-built dashboard or a third party's summary statistics, all metrics here are derived from raw relational data through original SQL queries, which is a deliberate choice: it forces explicit handling of the data quality issues (inconsistent date formats, incomplete order lifecycles, small-sample categories) that a pre-aggregated dataset would otherwise hide.

## Problem Statement

The analysis is organized around three questions, each corresponding to one of the forces described above:

1. **Growth** — How has revenue evolved on a monthly basis, and which product categories are responsible for the bulk of it?
2. **Logistics** — Is Olist meeting its stated delivery estimates, and does performance vary meaningfully by geography or over time?
3. **Satisfaction** — How do customers rate their experience, and is there evidence that satisfaction moves together with delivery performance rather than independently of it?

The third question is the most important one methodologically, because it is where the analysis moves from descriptive reporting ("what happened") toward an interpretive claim ("why it might have happened") — and where the limitations of a purely SQL-based, non-experimental analysis need to be stated explicitly rather than glossed over.

## Dataset Overview

The raw data is distributed as eight relational CSV files, which this project imports into a normalized MySQL schema:

| Table | Description |
|---|---|
| `orders` | Core order record — status and purchase/approval/delivery timestamps |
| `order_items` | Line items per order — product, seller, price, and freight value |
| `order_payments` | Payment method and installment count |
| `order_reviews` | Post-purchase review score and free-text comments |
| `customers` | Customer location (city, state) |
| `products` | Product attributes, linked to category |
| `sellers` | Seller location |
| `category_translation` | Maps Portuguese category names to their English equivalents |

Tables are joined on `order_id`, `customer_id`, or `product_category_name` depending on the query. It is worth noting that `customers` records the *delivery destination*, not the seller's origin — a distinction that matters for how the state-level results below should be interpreted, since a slow delivery to a given state does not necessarily mean the bottleneck originates there.

## Tools

The project uses MySQL for schema design, data import, and all analytical querying, and Power BI solely for presenting the query outputs as an interactive dashboard. No transformation logic lives in Power BI; every number shown in the dashboard is the direct output of a SQL query in this repository, which keeps the analysis reproducible and auditable end to end.

## Methodology

### Database setup (`olist_setup_updated.sql`)

The script creates all eight tables with explicit column types and loads each CSV using `LOAD DATA LOCAL INFILE`, followed by a row-count validation query across all tables to confirm the import completed without truncation before any analysis begins.

A data quality issue surfaces immediately at this stage and shapes every subsequent query: the date fields (`order_purchase_timestamp`, `order_delivered_customer_date`, and so on) import as raw strings in `MM/DD/YYYY HH:MM` format rather than native `DATETIME` values. This means no query in the project can perform date arithmetic directly — every comparison or extraction first requires an explicit `STR_TO_DATE(column, '%m/%d/%Y %H:%i')` conversion. This is a small detail, but it is the kind of detail that, left unhandled, silently produces wrong results (e.g., string-sorted dates rather than chronologically-sorted ones) without throwing an error — so it was treated as a first-class constraint rather than an afterthought.

### Time series analysis (`01_time_series_analysis.sql`)

Three queries aggregate order-level data by year and month of purchase:

- **Sales trend** — total order count, total revenue (defined as `price + freight_value` summed across order items), and the resulting average order value per month.
- **Delivery performance** — average delivery time in days, average days early or late relative to the estimated delivery date, and an on-time delivery rate computed via conditional aggregation:

```sql
ROUND(SUM(CASE 
    WHEN STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i') 
         <= STR_TO_DATE(o.order_estimated_delivery_date, '%m/%d/%Y %H:%i')
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS on_time_pct
```

- **Customer satisfaction** — average review score per month, with a count split between positive (score ≥ 4) and negative (score ≤ 2) reviews, computed alongside the average delivery time for the same period so the two series can be compared directly.

All three queries restrict to `order_status = 'delivered'`, which is a deliberate scope decision: cancelled or otherwise unfulfilled orders have no meaningful delivery time or review, and including them would distort both metrics. The tradeoff is that this analysis says nothing about cancellation rates themselves, which is flagged explicitly in the Limitations section below.

### State-level analysis (`02_state_analysis.sql`)

Joins `orders`, `customers`, and `order_reviews` to compute order volume, average review score, average delivery time, and on-time percentage grouped by customer state. This is where geographic disparities in service quality — which a national average necessarily hides — become visible.

### Category analysis (`03_category_analysis.sql`)

Joins `orders` → `order_items` → `products` → `category_translation` → `order_reviews` to compute average review score and average delivery time per product category, using the English category names for readability.

A statistical filter is applied here that is worth explaining rather than skipping over: `HAVING COUNT(DISTINCT o.order_id) >= 100`. Without this filter, a category with only three or four orders and a single poor review would appear in the results with an average review score every bit as "reliable" as a category built on several thousand orders — the small-sample category's average would simply be noisier, not less prominent in the output. Filtering by a minimum order count is a basic but necessary safeguard against mistaking sampling noise for a genuine performance difference.

## Results and Discussion

### Sales trend

Total revenue across the observed period reached **R$14.84M**. The monthly trend shows steady, largely uninterrupted growth from approximately R$0.1M in January 2017 to a peak near **R$1.18M** in late 2017, after which revenue plateaus in the R$1.0–1.15M range through mid-2018 rather than continuing to grow. This plateau is itself informative: it suggests the marketplace had reached a relatively stable demand level by that point, rather than still being in an early growth phase, though confirming that with confidence would require comparing against seller count and active-customer trends, which this dataset does not directly provide in the queries run here.

![Sales Trend](screenshots/sales_trend.png)

By product category, `health_beauty` generates the highest revenue among categories with sufficient order volume, followed by `watches_gifts` and `bed_bath_table`. The lowest-revenue category among the top ten, `garden_tools`, generates roughly half of the top category's revenue — indicating that revenue is concentrated in a handful of categories rather than distributed evenly, which has implications for how inventory and marketing investment might reasonably be prioritized.

### Delivery performance

The overall on-time delivery rate is **95.14%**, which on its own reads as a strong operational result. The monthly trend, however, shows this headline figure conceals meaningful variation over time: average delivery time rose from roughly 11–13 days in most of 2017 to a peak of approximately **17 days in early 2018**, before falling sharply to around **9 days by mid-2018**. A national average calculated across the full period would understate how bad the early-2018 period actually was for customers ordering at that time, and would equally fail to credit whatever operational change produced the mid-2018 recovery.

![Delivery Performance](screenshots/delivery_performance.png)

The geographic breakdown shows the same pattern of a favorable average obscuring underlying disparity. The five states with the longest average delivery times are RR (Roraima, ~29 days), AP (Amapá, ~27 days), AM (Amazonas, ~26.5 days), AL (Alagoas, ~25 days), and PA (Pará, ~24 days) — all located in Brazil's North or Northeast regions, geographically distant from the São Paulo-centric seller base that dominates the Olist network. This is consistent with a straightforward logistical explanation (longer physical distance and less developed delivery infrastructure), though the dataset alone cannot distinguish that explanation from others, such as regional differences in customs or last-mile carrier capacity.

### Customer satisfaction

The overall average review score is **4.07 out of 5**. The monthly trend shows a pronounced dip to approximately **3.78 in early 2018** — occurring in the same window where average delivery time peaked near 17 days — followed by a recovery to roughly **4.27 by mid-2018**, tracking the same timing as the delivery-time recovery described above.

![Customer Satisfaction](screenshots/customer_satisfaction.png)

At the state level, PE (Pernambuco) records the highest average review score (~4.0) among the states considered, while RR (Roraima) records the lowest (~3.6) — the same state identified above as having the longest average delivery time.

## Key Finding: The RR Correlation

Two independent breakdowns of the data — one by time, one by geography — point toward the same conclusion. Temporally, the month with the worst average delivery performance (~17 days) is also the month with the lowest average review score (~3.78). Geographically, the state with the worst average delivery performance (RR, ~29 days) is also the state with the lowest average review score (~3.6).

It would be an overreach to call this a proven causal relationship on the strength of two aggregated correlations alone — review scores are also shaped by product quality, pricing expectations, packaging condition, and seller communication, none of which are controlled for here. What can be said with reasonable confidence is that the alignment across two independent dimensions of the data makes delivery delay a strong candidate explanation for a meaningful share of dissatisfaction, and a more credible one than if the pattern had appeared in only one of the two breakdowns.

## Limitations

- Review scores reflect more than delivery time; no attempt is made here to isolate delivery's contribution from other drivers of satisfaction (e.g., through regression or controlled comparison), so the RR finding above should be read as a correlation warranting further investigation, not a settled causal claim.
- All delivery and satisfaction metrics are scoped to `order_status = 'delivered'`, which excludes cancelled and unfulfilled orders. Cancellation rate and its drivers are outside the scope of this analysis.
- Revenue is defined as `price + freight_value` combined; a reader interested specifically in merchandise revenue net of shipping cost recovery would need to separate these two components.
- Geographic analysis is based on customer (delivery destination) state, not seller (origin) state, so it measures where delays are experienced, not necessarily where in the supply chain they originate.

## Conclusion and Recommendations

Olist's logistics network performs well in aggregate — a 95.14% on-time rate is a genuinely strong figure — but that aggregate conceals both a seasonal dip and a persistent geographic gap that a single summary statistic would not surface. Two recommendations follow directly from the analysis:

1. Prioritize logistics investment in the North and Northeast states identified above (RR, AP, AM, AL, PA), since these states are simultaneously the slowest to deliver and the least satisfied, making them the highest-leverage target for service improvement relative to their current baseline.
2. Investigate the operational cause of the early-2018 slowdown in delivery time and the subsequent mid-2018 recovery. Identifying what changed operationally during that recovery could allow Olist to apply the same fix proactively rather than reactively the next time delivery performance degrades.

## Repository Structure

```
olist_setup_updated.sql        Schema creation and CSV import
01_time_series_analysis.sql    Monthly sales, delivery, and satisfaction trends
02_state_analysis.sql          Performance breakdown by customer state
03_category_analysis.sql       Performance breakdown by product category
screenshots/                   Power BI dashboard exports referenced above
```

## How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
2. Update the file paths in `olist_setup_updated.sql` to match the local CSV location.
3. Run `olist_setup_updated.sql` in MySQL Workbench to create the schema and import the data.
4. Run `01_time_series_analysis.sql`, `02_state_analysis.sql`, and `03_category_analysis.sql`, in that order.
5. Connect Power BI (or any BI tool) to the query outputs to reproduce the dashboard.

## Author

Risma Choerunnisa
[GitHub](https://github.com/rismanshaa) · [Live project page](https://rismanshaa.github.io/Analyze-the-Brazillian-E-commerce-Public-Dataset-by-Olist-with-SQL/)

## License

This project is licensed under the [MIT License](LICENSE).
