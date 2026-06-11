# Brazilian E-Commerce Analysis (Olist Dataset)

An end-to-end data analysis project using SQL and Power BI to explore sales performance, delivery efficiency, and customer satisfaction of a Brazilian e-commerce platform.

---

## Tools & Technologies
- **SQL** (MariaDB via HeidiSQL) — data extraction and analysis
- **Power BI** — interactive dashboard and visualization

## Dataset
Public dataset from [Olist Brazilian E-Commerce on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), covering ~100K orders from 2017–2018.

---

## Analysis Structure

### 1. Sales Trend
Analyzed monthly revenue and order volume over time, and identified top-performing product categories.

### 2. Delivery Performance
Measured average delivery days by month and by customer state, and calculated overall on-time delivery rate.

### 3. Customer Satisfaction
Tracked average review scores over time and across customer states to identify satisfaction patterns.

---

## Key Insights

- **Revenue grew consistently** from January 2017 to mid-2018, peaking at ~1.2M in November 2017 — likely driven by Black Friday demand
- **Health & Beauty** was the top revenue-generating category, significantly ahead of other categories
- **On-time delivery rate: 95.14%** — strong overall logistics performance
- **States RR, AP, and AM** had the longest average delivery times (>25 days), reflecting geographic challenges in remote regions of Brazil
- **Average review score: 4.07/5** — generally positive, with a notable dip in March 2018 despite high order volume, suggesting a potential operational issue worth further investigation

---

## Dashboard Preview

### Sales Trend
![Sales Trend](screenshots/sales_trend.png)

### Delivery Performance
![Delivery Performance](screenshots/delivery_performance.png)

### Customer Satisfaction
![Customer Satisfaction](screenshots/customer_satisfaction.png)

---

## Repository Structure
```
├── 01_time_series_analysis.sql   # Monthly trend analysis (revenue, delivery, reviews)
├── 02_state_analysis.sql         # Performance breakdown by customer state
├── 03_category_analysis.sql      # Performance breakdown by product category
├── olist_setup_updated.sql       # Database setup
└── screenshots/                  # Dashboard screenshots
```
