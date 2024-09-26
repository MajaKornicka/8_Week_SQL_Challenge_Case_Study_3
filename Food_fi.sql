


--                   A. Customer Journey
--  Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customers onboarding journey.
--  Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

  SELECT customer_id, s.plan_id, start_date, plan_name
  FROM subscriptions s
  LEFT JOIN plans ON s.plan_id = plans.plan_id
  WHERE customer_id IN (1,2,11,13,15,16, 18,19)
  




 
---------------- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) as customer_count
FROM subscriptions


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

WITH Month_distribution AS
(SELECT
	CASE WHEN start_date BETWEEN '2020-01-01' AND '2020-01-31' THEN '1. January'
		 WHEN start_date BETWEEN '2020-02-01' AND '2020-02-29' THEN '2. February'
		 WHEN start_date BETWEEN '2020-03-01' AND '2020-03-31' THEN '3. March'
		 WHEN start_date BETWEEN '2020-04-01' AND '2020-04-30' THEN '4. April'
		 WHEN start_date BETWEEN '2020-05-01' AND '2020-05-31' THEN '5. May'
		 WHEN start_date BETWEEN '2020-06-01' AND '2020-06-30' THEN '6. June'
		 WHEN start_date BETWEEN '2020-07-01' AND '2020-07-31' THEN '7. July'
		 WHEN start_date BETWEEN '2020-08-01' AND '2020-08-31' THEN '8. August'
		 WHEN start_date BETWEEN '2020-09-01' AND '2020-09-30' THEN '9. September'
		 WHEN start_date BETWEEN '2020-10-01' AND '2020-10-31' THEN '10. October'
		 WHEN start_date BETWEEN '2020-11-01' AND '2020-11-30' THEN '11. November'
		 WHEN start_date BETWEEN '2020-12-01' AND '2020-12-31' THEN '12. December'
	ELSE 'O'
	END AS trials_by_month
FROM subscriptions s
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'trial')

SELECT*, count(trials_by_month) AS trials_count
FROM Month_distribution
GROUP BY trials_by_month
ORDER BY 2 desc

SELECT  DATETRUNC(month, start_date) as month, COUNT(customer_id) as trial_starts
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATETRUNC(month, start_date)


-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT plan_name, COUNT(plan_name) as plan_count
FROM subscriptions s
LEFT JOIN plans p on s.plan_id = p.plan_id
WHERE start_date > '2020-12-31'
GROUP BY plan_name

 

 -- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
 
 SELECT 
 (SELECT count(distinct customer_id) FROM subscriptions) as customer_count , 
ROUND((CAST(count(distinct customer_id) AS FLOAT) / (SELECT CAST(count(distinct customer_id)AS FLOAT) FROM subscriptions)) *100,1) as chrun_rate
FROM subscriptions 
WHERE plan_id = 4



-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH ranking AS
(SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY start_date) as rank
 FROM foodie_fi.dbo.subscriptions)

 SELECT
		COUNT(CASE WHEN plan_name = 'churn' AND rank = 2 THEN 1 END),
		 ROUND(CAST(COUNT(CASE WHEN plan_name = 'churn' AND rank = 2 THEN 1 END) AS FLOAT)
		  / CAST(COUNT(DISTINCT customer_id)AS FLOAT) * 100,0)
  AS churn_count
 FROM ranking
 JOIN Foodie_Fi.dbo.plans ON ranking.plan_id = plans.plan_id



--6. What is the number and percentage of customer plans after their initial free trial?

WITH ranking AS(
SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY start_date) as rank
FROM foodie_fi.dbo.subscriptions)

SELECT ranking.plan_id, plan_name, COUNT(plan_name) as conversions, 
		ROUND((CAST(Count(plan_name) AS NUMERIC) / (SELECT COUNT(plan_id) from ranking where rank = 2) *100),1)
FROM ranking
JOIN Foodie_Fi.dbo.plans ON ranking.plan_id = plans.plan_id
WHERE rank = 2
GROUP BY plan_name, ranking.plan_Id
ORDER BY plan_id
 

 -- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
 
WITH ranking AS
(SELECT *, RANK() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rank
FROM foodie_fi.dbo.subscriptions
WHERE start_date<= '2020-12-31')

SELECT plan_name, COUNT(ranking.plan_id) count_of_plans,
		ROUND(CAST(COUNT(ranking.plan_id)AS NUMERIC) 
		/ CAST((SELECT COUNT(customer_id) FROM ranking WHERE rank = 1) AS NUMERIC)*100,1) AS rate
FROM ranking
JOIN Foodie_Fi.dbo.plans ON ranking.plan_id = plans.plan_id
WHERE rank = 1
GROUP BY plan_name
ORDER BY  COUNT(ranking.plan_id) desc

-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT Count(DISTINCT customer_id)
FROM Foodie_Fi.dbo.subscriptions
WHERE plan_id = 3
AND YEAR(start_date) = '2020'

SELECT*
FROM Foodie_Fi.dbo.plans

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH annual AS
(SELECT customer_id AS customer_an, start_date as end_Date
FROM  Foodie_Fi.dbo.subscriptions
WHERE plan_id = 3),

trial AS
(SELECT customer_id AS customer_trial, start_date as first_Date
FROM  Foodie_Fi.dbo.subscriptions
WHERE plan_id = 0)

SELECT AVG(DATEDIFF(day, first_date, end_date)) as difference
FROM annual
LEFT JOIN trial ON annual.customer_an = trial.customer_trial


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)


WITH annual AS
(SELECT customer_id AS customer_an, start_date as end_Date
FROM  Foodie_Fi.dbo.subscriptions
WHERE plan_id = 3),

trial AS
(SELECT customer_id AS customer_trial, start_date as first_Date
FROM  Foodie_Fi.dbo.subscriptions
WHERE plan_id = 0)

SELECT 
	CASE WHEN DATEDIFF(day, first_date, end_date) <=30 THEN '0-30'
	     WHEN DATEDIFF(day, first_date, end_date) <=60 THEN '31-60'
		 WHEN DATEDIFF(day, first_date, end_date) <=90 THEN '61-90'
		 WHEN DATEDIFF(day, first_date, end_date) <=120 THEN '91-120'
		 WHEN DATEDIFF(day, first_date, end_date) <=150 THEN '121-150'
		 WHEN DATEDIFF(day, first_date, end_date) <=180 THEN '151-180'
		 WHEN DATEDIFF(day, first_date, end_date) <=210 THEN '181-210'
		 WHEN DATEDIFF(day, first_date, end_date) <=240 THEN '211-240'
		 WHEN DATEDIFF(day, first_date, end_date) <=270 THEN '241-270'
		 WHEN DATEDIFF(day, first_date, end_date) <=330 THEN '300-330'
		  ELSE '331-360'
	END as days_division,
	count(customer_an) as cust_count
FROM annual
LEFT JOIN trial ON annual.customer_an = trial.customer_trial
GROUP BY (CASE WHEN DATEDIFF(day, first_date, end_date) <=30 THEN '0-30'
	     WHEN DATEDIFF(day, first_date, end_date) <=60 THEN '31-60'
		 WHEN DATEDIFF(day, first_date, end_date) <=90 THEN '61-90'
		 WHEN DATEDIFF(day, first_date, end_date) <=120 THEN '91-120'
		 WHEN DATEDIFF(day, first_date, end_date) <=150 THEN '121-150'
		 WHEN DATEDIFF(day, first_date, end_date) <=180 THEN '151-180'
		 WHEN DATEDIFF(day, first_date, end_date) <=210 THEN '181-210'
		 WHEN DATEDIFF(day, first_date, end_date) <=240 THEN '211-240'
		 WHEN DATEDIFF(day, first_date, end_date) <=270 THEN '241-270'
		 WHEN DATEDIFF(day, first_date, end_date) <=330 THEN '300-330'
		 ELSE '331-360'
	END )
ORDER BY 2 desc


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH pro_monthly_2 AS(
SELECT *
FROM subscriptions
WHERE YEAR(start_date) = 2020
AND plan_id =2),

basic_monthly_1 AS (
SELECT *
FROM subscriptions
WHERE YEAR(start_date) = 2020
AND plan_id =1)

SELECT * 
FROM pro_monthly_2
LEFT JOIN basic_monthly_1 ON pro_monthly_2.customer_id = basic_monthly_1.customer_id
WHERE pro_monthly_2.start_date < basic_monthly_1.start_date



*/


