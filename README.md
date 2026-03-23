# 🛒 Olist E-Commerce SQL Analytics Project

## 📌 Project Overview
This project performs end-to-end SQL analysis on the **Brazilian E-Commerce Public Dataset by Olist** — one of the most popular real-world datasets for data analytics. The goal is to extract actionable business insights using advanced SQL techniques including CTEs, window functions, date functions, and RFM/Cohort analysis frameworks.

---

## 📂 Dataset
- **Source:** [Kaggle — Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Size:** ~1.5 million records across 9 relational tables
- **Period:** 2016 – 2018
- **Domain:** Brazilian E-Commerce

### Tables
| Table | Rows | Description |
|---|---|---|
| customers | 99,441 | Customer info and location |
| orders | 99,441 | Order status and timestamps |
| order_items | 112,650 | Products within each order |
| order_payments | 103,886 | Payment details per order |
| order_reviews | 99,223 | Customer review scores |
| products | 32,951 | Product info and category |
| sellers | 3,095 | Seller info and location |
| geolocation | 1,000,163 | ZIP code coordinates |
| product_category_translation | 71 | Portuguese to English category names |

---

## 🛠️ Tools Used
- **Database:** MySQL 8.0
- **IDE:** MySQL Workbench
- **Dataset:** Kaggle (CSV files)
- **Version Control:** GitHub

---

## 🗂️ Project Structure
```
olist-sql-project/
│
├── README.md
├── schema/
│   ├── 01_create_tables.sql       -- CREATE TABLE statements for all 9 tables
│   └── 02_add_keys.sql            -- Primary Keys and Foreign Keys
│
├── analysis/
│   ├── 01_business_overview.sql   -- Revenue, order status, monthly trends
│   ├── 02_delivery_performance.sql -- Delivery time, late orders by state
│   ├── 03_seller_performance.sql  -- Seller ranking, revenue, review scores
│   ├── 04_rfm_segmentation.sql    -- Customer RFM segmentation
│   ├── 05_product_analysis.sql    -- Category revenue, MoM growth
│   ├── 06_payment_analysis.sql    -- Payment type analysis, pivot
│   └── 07_cohort_analysis.sql     -- Customer retention cohort analysis
│
└── images/
    └── erd_diagram.png            -- Entity Relationship Diagram
```

---

## 🗄️ Schema & ERD

The schema follows a **star schema** design with `orders` as the central fact table connected to dimension tables via foreign keys.

> 📸 *(Add your ERD screenshot here)*

### Relationships
- `orders` → `customers` (customer_id)
- `order_items` → `orders` (order_id)
- `order_items` → `products` (product_id)
- `order_items` → `sellers` (seller_id)
- `order_payments` → `orders` (order_id)
- `order_reviews` → `orders` (order_id)
- `products` → `product_category_translation` (product_category_name)

---

## 📊 Key Analyses

### 1. Business Overview
- Total revenue, order volume and order status distribution
- Monthly revenue trend across 22 months
- Top 10 states by number of customers
- Used: `GROUP BY`, `DATE_FORMAT`, `COUNT DISTINCT`, `OVER()`

### 2. Delivery Performance
- Average delivery time by state
- On-time vs late delivery breakdown
- Top 10 worst states by late delivery percentage
- Used: `DATEDIFF`, `CASE WHEN`, `CTE`

### 3. Seller Performance
- Top 10 sellers by revenue with review scores
- Seller ranking using window functions
- Best seller per state using `PARTITION BY`
- Used: `RANK()`, `NTILE()`, `PARTITION BY`, chained CTEs

### 4. Customer RFM Segmentation
- Scored each customer on Recency, Frequency, Monetary value
- Segmented customers into: Champion, Loyal, New, At Risk, Lost, Potential Loyalist
- Used: `NTILE()`, 3 chained CTEs, business logic with `CASE WHEN`

### 5. Product Analysis
- Top 10 product categories by revenue
- Freight cost as % of product price by category
- Month-over-Month revenue growth for top 5 categories
- Used: `LAG()`, `COALESCE`, `PARTITION BY`, `HAVING`

### 6. Payment Analysis
- Revenue and transaction count by payment type
- Year-wise PIVOT of payment methods
- Order value bucketing with installment analysis
- Used: PIVOT with `CASE WHEN`, value bucketing, `OVER()`

### 7. Cohort Analysis
- Grouped customers by first purchase month
- Tracked retention rate for 6 months after first purchase
- Identified which cohorts had the highest retention
- Used: 5 chained CTEs, `PERIOD_DIFF`, `DATE_FORMAT`

---

## 🔍 Key Findings

- 🚚 **AL (Alagoas) has the worst delivery performance** — nearly 1 in 4 orders (23.93%) delivered late, followed by MA (19.67%) and PI (15.97%)
- 💳 **Credit card dominates payments** — most used payment method across all years, with customers preferring installment payments for high-value orders
- 👥 **São Paulo drives the business** — SP has 40,302 customers, 3x more than RJ (12,384) and MG (11,259)
- 📦 **Bed & Bath is the top revenue category** — showed explosive MoM growth of 694% in early 2017
- 🔄 **Customer retention drops sharply after first purchase** — cohort analysis reveals Olist is heavily dependent on new customer acquisition
- ⭐ **Seller quality varies significantly** — top sellers by revenue don't always have the best review scores, showing a trade-off between volume and quality

---

## ▶️ How to Run

1. Install **MySQL 8.0** and **MySQL Workbench**
2. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
3. Run `schema/01_create_tables.sql` to create all tables
4. Load CSV files using `LOAD DATA LOCAL INFILE` or MySQL Workbench Import Wizard
5. Run `schema/02_add_keys.sql` to add Primary Keys and Foreign Keys
6. Run any analysis file from the `analysis/` folder

```sql
-- Quick start
USE olist_db;
SOURCE analysis/01_business_overview.sql;
```

---

## 💡 SQL Concepts Demonstrated

| Concept | Used In |
|---|---|
| CTEs (`WITH` clause) | Analysis 2, 3, 4, 5, 6, 7 |
| Window Functions (`RANK`, `NTILE`, `LAG`) | Analysis 3, 4, 5, 6 |
| `PARTITION BY` | Analysis 3, 5 |
| `CASE WHEN` | Analysis 2, 6 |
| Date Functions (`DATEDIFF`, `DATE_FORMAT`, `PERIOD_DIFF`) | Analysis 2, 5, 7 |
| `COALESCE` for NULL handling | Analysis 5, 6 |
| PIVOT technique | Analysis 6 |
| Cohort Analysis | Analysis 7 |
| RFM Segmentation | Analysis 4 |
| Subquery optimization | Analysis 5 |

---

## 👨‍💻 Author
**Ramiz**
Data Engineer | 2+ Years Experience
- 📧 beigramizx@gmail.com.com
- 💼 [LinkedIn](https://www.linkedin.com/in/ramiz-beig/)
