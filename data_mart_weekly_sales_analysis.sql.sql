-- DATA CLEANING

/* 1.	Add a week_number as the second column for each week_date value, for example any
 value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2, etc.*/
ALTER TABLE weekly_sales
ADD COLUMN week_number int AFTER week_date;

UPDATE weekly_sales
SET month_number = EXTRACT(WEEK FROM week_date);

-- 2.Add a month_number with the calendar month for each week_date value as the 3rd column
ALTER TABLE weekly_sales
ADD COLUMN month_number int AFTER week_number;

UPDATE weekly_sales
SET month_number = EXTRACT(MONTH FROM week_date);

-- 3.Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
ALTER TABLE weekly_sales
ADD COLUMN calender_year int AFTER month_number;

UPDATE weekly_sales
SET calender_year = EXTRACT(YEAR FROM week_date);

/*4.Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees
*/
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
            
/*5.Add a new demographic column using the following mapping for the first letter in the segment values:
segment | demographic |
C | Couples |
F | Families |
*/

ALTER TABLE weekly_sales
ADD COLUMN demographic VARCHAR(15) AFTER age_band;

UPDATE weekly_sales
SET demographic = 
		(CASE
			WHEN segment IN('F1', 'F2', 'F3') THEN 'Families'
            WHEN segment IN('C1', 'C2','C3', 'C4') THEN 'Couples'
		ELSE 'Unknown'
        END);
        
-- 6.Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns      
UPDATE weekly_sales
SET segment = 'Unknown'
WHERE segment = 'null';

-- 7.Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
ALTER TABLE weekly_sales
ADD COLUMN avg_transaction FLOAT;

UPDATE weekly_sales
SET avg_transaction = round((sales/transactions),2);

-- DATA EXPLORATION
-- 1.Which week numbers are missing from the dataset?
    CREATE TABLE num ( number_ int);
    INSERT INTO num
VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
       (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
       (21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
       (31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
       (41),(42),(43),(44),(45),(46),(47),(48),(49),(50),
       (51),(52);
SELECT * FROM num;

WITH find_missing_weeks
AS
(SELECT  n.number_,w.week_number
   FROM num AS n
LEFT JOIN weekly_sales AS W
ON n.number_ = W.week_number)

SELECT number_ AS missing_weeks
FROM find_missing_weeks
WHERE week_number is null;

-- 2.How many total transactions were there for each year in the dataset?
SELECT calender_year, COUNT(*) AS total_transactions
FROM weekly_sales
GROUP BY calender_year
ORDER BY calender_year;

-- 3.What are the total sales for each region for each month?
SELECT region, month_number,SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY month_number, region
ORDER BY SUM(sales) DESC;

-- 4.What is the total count of transactions for each platform
SELECT platform, COUNT(transactions) AS total_count
FROM weekly_sales
GROUP BY platform
ORDER BY COUNT(transactions);

-- 5.	What is the percentage of sales for Retail vs Shopify for each month?
SELECT month_number, platform, 
(SUM(sales)*100)/SUM(SUM(sales))  OVER ( PARTITION BY month_number) AS sale_percentage
FROM weekly_sales
GROUP BY month_number, platform;

-- 6.	What is the percentage of sales by demographic for each year in the dataset?
SELECT calender_year, demographic,
(SUM(sales)*100)/SUM(SUM(sales))  OVER ( PARTITION BY calender_year) AS sale_percentage
FROM weekly_sales
GROUP BY calender_year, demographic;

-- 7.	Which age_band and demographic values contribute the most to Retail sales?
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

-- END