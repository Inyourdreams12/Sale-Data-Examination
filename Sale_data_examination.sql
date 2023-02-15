USE new_schema;

-- Inspecting Data
SELECT * FROM sales_data_sample;
SELECT STR_TO_DATE('2/24/2003 0:00', '%m/%d/%Y %H:%i');
UPDATE sales_data_sample SET ORDERDATE = STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i');


-- Checking unique values
SELECT DISTINCT STATUS FROM sales_data_sample; -- nice one to plot in tableau
SELECT DISTINCT YEAR_ID FROM sales_data_sample;-- time frame of the dataset , 3 years
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample;-- 7 different products
SELECT DISTINCT COUNTRY FROM sales_data_sample;-- nice to plot
SELECT DISTINCT DEALSIZE FROM sales_data_sample;-- nice to plot, have M/L/S
SELECT DISTINCT TERRITORY FROM sales_data_sample;-- nice to plot



-- ANALYSIS
-- -- Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;  -- classic cars is the best productline they have, followed by vintage cars

SELECT YEAR_ID, SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC;  -- 2004 is the year they made the most sales, 2005 is pretty low because they operated just half of the year

SELECT DISTINCT MONTH_ID FROM sales_data_sample WHERE YEAR_ID = 2005;

SELECT DEALSIZE, SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC;  -- the medium size are the one that generates the most revenue


-- -- What was the best month for sales in specific year? How much was earned that month?
SELECT MONTH_ID, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC;

SELECT MONTH_ID, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC; -- november is the expectional for this company, revenue almost twice the second month for both 2003&2004


-- -- November seem to be the best month, what product do they sell in November? I think classic cars first
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;  -- 2004 reflect the same result




-- RFM ANALYSIS (Recency, Requency, Monetary)
-- -- Who is our best customer?
DROP TABLE IF EXISTS rfmtable;
CREATE TABLE rfmtable AS
WITH rfm AS
(
	SELECT CUSTOMERNAME,
		   SUM(SALES) AS MonetaryValue,
		   AVG(SALES) AS Avg_MonetaryValue,
		   COUNT(ORDERNUMBER) AS Frequency,
		   MAX(ORDERDATE) AS last_order_date, -- date that group by
		   (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,-- date entire dataset
		   DATEDIFF((SELECT MAX(ORDERDATE) FROM sales_data_sample), MAX(ORDERDATE)) AS Recency
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME    
),
rfm_calculation AS -- divides a result set into 4 equal-sized groups
(
	SELECT *,
		   NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
		   NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		   NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
	FROM rfm
)
SELECT *, CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS rfm_string
FROM rfm_calculation;

SHOW TABLES;

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary, 
       CASE
			WHEN rfm_string IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'Lost customer' -- lost customer
            WHEN rfm_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'Slipping away, cannot lose' -- big spenders who havent purchase lately
			WHEN rfm_string IN (311, 411, 331) THEN 'New customers'
            WHEN rfm_string IN (222, 223, 233, 322) THEN 'Potential churners'
            WHEN rfm_string IN (323, 333,321, 422, 332, 432) THEN 'Active'  -- customer who buy often and recently, but at low price points
			WHEN rfm_string IN (433, 434, 443, 444) THEN 'Loyal' 
	   END AS rfm_segment
FROM rfmtable
ORDER BY rfm_segment DESC; -- After catagorize our customers, whenever we want to setup marketing campaign or sometype of advertising, we know what group we should target for which program
            
            
-- -- What product are often sold together?
SELECT DISTINCT ORDERNUMBER,   
(
	SELECT GROUP_CONCAT(PRODUCTCODE SEPARATOR ',') AS product_codes -- a list of product code from order that have 2 product in 1 order
	FROM sales_data_sample AS p
	WHERE ORDERNUMBER IN
		(	
			SELECT ORDERNUMBER -- find order that have 2 product in 1 order
			FROM
				(
				SELECT ORDERNUMBER, COUNT(*) AS rn -- find the order that have shipped
				FROM sales_data_sample
				WHERE STATUS = 'Shipped'       
				GROUP BY ORDERNUMBER  
				) AS m
			WHERE rn = 2 -- 2 sold together, we can change into 3
		)
        AND p.ORDERNUMBER = s.ORDERNUMBER
) AS List_productcode
FROM sales_data_sample s
ORDER BY 2 DESC; -- Order 10243 and 10409 has the 2 productcode that sold together
 -- We can run some promotion/campaign/advertising cause we know the higher chance decision of customer will buy this 2 product together

