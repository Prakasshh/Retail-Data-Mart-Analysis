# Data Mart Analysis (SQL)

## 📌 Project Overview
This project focuses on **in-depth Data Mart analysis using SQL** to uncover key business trends and performance metrics.  
The goal was to explore, clean, and analyze data stored in a Data Mart to generate actionable insights for decision-making.

---
## 📂 Dataset
- **Source**: Data Mart
- **Data Type**: Transactional sales data
- **Used Schema**:
  
![Dashboard Screenshot](https://github.com/Prakasshh/Retail-Data-Mart-Analysis/blob/main/Used%20Schema.png?raw=true)

---

## 🧹 A. Data Cleansing Steps
Cleaned and transformed data into a structured table clean_weekly_sales within the data_mart schema.

**Transformations Applied:**
1. **Week Number**  
   - Added `week_number` as the second column.  
   - Mapping:  
     - 1st Jan – 7th Jan → Week 1  
     - 8th Jan – 14th Jan → Week 2  
     - and so on.

 **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN week_number int AFTER week_date;

UPDATE weekly_sales
SET month_number = EXTRACT(WEEK FROM week_date);
```


2. **Month Number**  
   - Added `month_number` based on the calendar month from `week_date`.

 **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN month_number int AFTER week_number;

UPDATE weekly_sales
SET month_number = EXTRACT(MONTH FROM week_date);
```

3. **Calendar Year**  
   - Added `calendar_year` column containing values **2018**, **2019**, or **2020**.
  
   **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN calender_year int AFTER month_number;

UPDATE weekly_sales
SET calender_year = EXTRACT(YEAR FROM week_date);
```

4. **Age Band Mapping**  
   - Added `age_band` column after the `segment` column using:  
     | segment number | age_band      |  
     |----------------|--------------|  
     | 1              | Young Adults |  
     | 2              | Middle Aged  |  
     | 3 or 4         | Retirees     |
 **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN age_band VARCHAR(15) AFTER segment;

UPDATE weekly_sales
SET age_band = 
		(CASE
			WHEN segment IN('F1', 'C1') THEN 'Young_Adults'
            WHEN segment IN('F2', 'C2') THEN 'Middle_Aged'
            WHEN segment IN('F3', 'C3', 'C4') THEN 'Retirees'
		ELSE 'Unknown'
        END
);
```

5. **Demographic Mapping**  
   - Added `demographic` column using the first letter of the `segment` value:  
     | First Letter | demographic |  
     |--------------|-------------|  
     | C            | Couples     |  
     | F            | Families    |

 **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN demographic VARCHAR(15) AFTER age_band;

UPDATE weekly_sales
SET demographic = 
		(CASE
			WHEN segment IN('F1', 'F2', 'F3') THEN 'Families'
            WHEN segment IN('C1', 'C2','C3', 'C4') THEN 'Couples'
		ELSE 'Unknown'
        END);
```

6. **Handling Nulls**  
   - Replaced all NULL or empty string values in `segment`, `age_band`, and `demographic` columns with `"unknown"`.
  
 **Query:**
```sql
UPDATE weekly_sales
SET segment = 'Unknown'
WHERE segment = 'null';
```

7. **Average Transaction Value**  
   - Created a new column `avg_transaction` as:  
     ROUND(sales / transactions, 2)

  **Query:**
```sql
ALTER TABLE weekly_sales
ADD COLUMN avg_transaction FLOAT;

UPDATE weekly_sales
SET avg_transaction = round((sales/transactions),2);
```
---

## 📊 B. Data Exploration

The following questions were answered using SQL queries on the `clean_weekly_sales` table to understand sales trends, platform performance, and customer demographics.

---

1. **Which week numbers are missing from the dataset?**  

**Query:**
```sql
CREATE TABLE num ( number_ INT );

INSERT INTO num
VALUES 
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
(41),(42),(43),(44),(45),(46),(47),(48),(49),(50),
(51),(52);

SELECT * FROM num;

WITH find_missing_weeks AS (
    SELECT n.number_, w.week_number
    FROM num AS n
    LEFT JOIN weekly_sales AS w
    ON n.number_ = w.week_number
)
SELECT number_ AS missing_weeks
FROM find_missing_weeks
WHERE week_number IS NULL;
   ```


2. **How many total transactions were there for each year in the dataset?**  
    **Query:**
```sql
   SELECT calender_year, COUNT(*) AS total_transactions
FROM weekly_sales
GROUP BY calender_year
ORDER BY calender_year;
```


3. **What are the total sales for each region for each month?**  
  **Query:**
```sql
SELECT region, month_number,SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY month_number, region
ORDER BY SUM(sales) DESC;
```

4. **What is the total count of transactions for each platform?**  
  **Query:**
```sql
SELECT platform, COUNT(transactions) AS total_count
FROM weekly_sales
GROUP BY platform
ORDER BY COUNT(transactions);
   ```

5. **What is the percentage of sales for Retail vs Shopify for each month?**  
  **Query:**
```sql
SELECT month_number, platform, 
(SUM(sales)*100)/SUM(SUM(sales)) OVER (PARTITION BY month_number) AS sale_percentage
FROM weekly_sales
GROUP BY month_number, platform;
   ```

6. **What is the percentage of sales by demographic for each year in the dataset?**  
  **Query:**
```sql
SELECT calender_year, demographic,
(SUM(sales)*100)/SUM(SUM(sales)) OVER ( PARTITION BY calender_year) AS sale_percentage
FROM weekly_sales
GROUP BY calender_year, demographic;
   ```

8. **Which age_band and demographic values contribute the most to Retail sales?**  
  **Query:**
```sql
WITH retail_sales AS (
    SELECT 
        'Age Band' AS category_type, 
        age_band AS category, 
        SUM(sales) AS total_sales
    FROM weekly_sales
    WHERE platform = 'Retail'
    GROUP BY age_band

    UNION ALL

    SELECT 
        'Demographic' AS category_type, 
        demographic AS category, 
        SUM(sales) AS total_sales
    FROM weekly_sales
    WHERE platform = 'Retail'
    GROUP BY demographic
)
SELECT 
    category_type,
    category,
    CONCAT(ROUND(total_sales / 1000000000.0, 1), ' B') AS total_sales_in_billions
FROM retail_sales
ORDER BY total_sales DESC
LIMIT 2;
   ```

---

## **Skills Used**
- **SQL Data Transformation** – Creating derived columns (`week_number`, `month_number`, `calendar_year`) using date functions and conditional logic.  
- **Data Mapping** – Categorizing `segment` values into `age_band` and `demographic` using CASE statements.  
- **Data Cleaning** – Handling and replacing NULL string values with `"unknown"`.  
- **Mathematical Calculations in SQL** – Computing `avg_transaction` from sales and transactions.  
- **Schema & Table Management** – Creating the clean dataset (`clean_weekly_sales`) in the `data_mart` schema.  
- **Single Query Optimization** – Executing all steps in one efficient SQL query.
- **SQL Aggregation** – Using `SUM()`, `COUNT()`, and grouping to summarize data.  
- **Filtering & Conditional Logic** – Applying `WHERE` clauses and conditional expressions for specific business questions.  
- **Date & Time Functions** – Extracting `month_number` and `calendar_year` for time-based analysis.  
- **Percentage Calculations in SQL** – Computing proportional values from aggregated data.  
- **Ranking & Ordering** – Using `ORDER BY` to identify top contributors.  
- **Data Validation** – Checking for missing or incomplete week numbers.

---


