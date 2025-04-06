CREATE TABLE walmart (
    invoice_id int,  
    branch varchar(15),
    city varchar(50),
    category varchar(50),
    unit_price DOUBLE PRECISION,     
    quantity DOUBLE PRECISION,       
    date DATE,
    time TIME,                       
    payment_method varchar(25),             
    rating DOUBLE PRECISION,
    profit_margin DOUBLE PRECISION,  
    total DOUBLE PRECISION           
);

SELECT * FROM walmart;

--Q1.What are the different payment methods, and how many transactions and items were sold with each method?
SELECT payment_method, 
	   COUNT(*)
FROM walmart
GROUP BY 1
ORDER BY 2;

--Q2. Which category received the highest average rating in each branch?
SELECT branch,
	   category,
	  avg_rating
FROM (
		SELECT branch,
				category,
				AVG(rating) AS avg_rating,
		RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
		FROM walmart
		GROUP BY branch, category
) AS ranked
WHERE rank = 1;

--Q3. What is the busiest day of the week for each branch based on transaction volume?
SELECT branch, day_name, total_transaction
FROM 
	(SELECT branch,
	   		TO_CHAR(date,'Day') AS day_name,
	   		COUNT(*) AS total_transaction,
	  	 	RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC ) AS rank
	   
	FROM walmart
	GROUP BY 1,2
	) 
WHERE rank = 1;

-- Q4. How many items were sold through each payment method?
SELECT payment_method,
	   count(*) Total_item_sold
FROM walmart
GROUP BY 1;

-- Q5. What are the average, minimum, and maximum ratings for each category in each city?
SELECT city,
	   category,
	   ROUND(AVG(rating)::numeric,2) AS avg_rating,
	   MIN(rating) AS min_rating,
	   MAX(rating) AS max_rating
FROM walmart
GROUP BY 1,2;

-- Q6. What is the total profit for each category, ranked from highest to lowest?
SELECT category,
	   ROUND(SUM(total)::numeric,2) AS total_revenue,
	   ROUND(SUM(total * profit_margin)::numeric,2) AS total_profit
FROM walmart
GROUP BY 1;

-- Q7. What is the most frequently used payment method in each branch?
SELECT branch,
		payment_method,
		total_transaction
FROM
(SELECT branch,
		payment_method,
		COUNT(*) AS total_transaction,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC ) AS rank
FROM walmart
GROUP BY 1,2)
WHERE rank =1;

-- Q8.How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT branch,
		COUNT(*) AS total_transaction,
CASE 
	WHEN EXTRACT(HOUR FROM (time::TIME)) < 12 THEN 'Morning'
	WHEN EXTRACT(HOUR FROM (time::TIME)) BETWEEN 12 AND 17 THEN 'Afternoon'
	ELSE 'Evening'
END AS shifts
FROM walmart
GROUP BY 1,3
ORDER BY 1,2;

-- Q9. Which branches experienced the largest decrease in revenue compared to the previous year?
WITH revenue_by_year AS (
SELECT branch,
		EXTRACT(YEAR FROM date) as transaction_year,
		ROUND(SUM(total)::numeric,2) as yearly_revenue
		
FROM walmart
GROUP BY 1,2
),
revenue_change AS (
    SELECT 
        branch,
        transaction_year,
        yearly_revenue,
        LAG(yearly_revenue) OVER (PARTITION BY branch ORDER BY transaction_year) AS prev_year_revenue,
        (yearly_revenue - LAG(yearly_revenue) OVER (PARTITION BY branch ORDER BY transaction_year)) AS revenue_change
    FROM revenue_by_year
)
SELECT
    branch,
    transaction_year,
    yearly_revenue,
    prev_year_revenue,
    revenue_change
FROM revenue_change
WHERE revenue_change < 0
ORDER BY revenue_change DESC;
