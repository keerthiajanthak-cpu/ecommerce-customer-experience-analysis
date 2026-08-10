# E-Commerce Customer Experience Analysis

SQL and Power BI analysis of e-commerce delivery performance and revenue, using the Olist Brazilian e-commerce dataset.

## Overview

This project analyzes over 96,000 delivered orders to uncover patterns in revenue, delivery performance, and customer experience across Brazilian states. The analysis combines MySQL for data processing with Power BI for visualization and storytelling.

## Key Findings

- **Delivery problem:** The state of MA has the highest late delivery rate at 23.65% — nearly 3x the national average of 7.84%. Northern and remote states consistently underperform on delivery timelines.
- **Category opportunity:** Health & beauty and watches/gifts are the top revenue categories at $1.5M and $1.3M respectively. However, office furniture has the longest average delivery time at 20.9 days.
- **Top performer:** SP state drives the highest order volume (68,635 orders) while maintaining a low 8.47% late delivery rate — proving high volume and strong delivery performance can coexist.

## Dashboard Highlights

- **Total Revenue:** $16M
- **Total Orders:** 96K
- **Late Delivery Rate:** 7.84%
- **Avg Delivery Days:** 12.4

## Tools Used

- **MySQL** — data cleaning, transformation, and analysis
- **Power BI** — dashboard and visualization

## Project Structure

```
ecommerce-customer-experience-analysis/
├── data/
│   ├── cleaned/
│   │   └── dashboard_data.csv
│   └── raw/
│       ├── olist_customers_dataset.csv
│       ├── olist_order_items_dataset.csv
│       ├── olist_order_payments_dataset.csv
│       ├── olist_order_reviews_dataset.csv
│       ├── olist_orders_dataset.csv
│       ├── olist_products_dataset.csv
│       ├── olist_sellers_dataset.csv
│       └── product_category_name_translation.csv
├── power bi/
│   └── Ecommerce_Analysis PowerBI Dashboard.pdf
├── screenshots/
│   └── Screenshot 2026-07-16 at 12.44.54 pm
└── sql/
    └── ecommerce_analysis_queries.sql
```

## Data Source

[Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

## How to Run

1. Import the raw CSVs from `data/raw/` into a MySQL database
2. Run the queries in `sql/ecommerce_analysis_queries.sql` in order (they're numbered and documented with business questions)
3. The final query builds a clean dataset used to power the Power BI dashboard
