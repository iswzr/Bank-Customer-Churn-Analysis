-- ============ Create Table =================== ---
CREATE TABLE customers (
    CustomerId BIGINT PRIMARY KEY,
    Surname VARCHAR(50),
    CreditScore INTEGER,
    Geography VARCHAR(50),
    Gender VARCHAR(10),
    Age INTEGER,
    Tenure INTEGER,
    Balance NUMERIC(18, 2),
    NumOfProducts INTEGER,
    HasCrCard BOOLEAN,
    IsActiveMember BOOLEAN,
    EstimatedSalary NUMERIC(18, 2),
    Exited BOOLEAN
);

-- =================== Upload csv file ======================== --
COPY customers
FROM 'D:/Israr/CSV datasets/Bank+Customer+Churn/Bank_Churn.csv'
DELIMITER ','
CSV HEADER;

-- ================== Basic Questions ========================= --
-- ======================= 1 ================================== --
-- Count the total number of customers in the dataset
SELECT 
    COUNT(*) AS total_customers
FROM customers;

-- ======================= 2 ================================ --
-- What is the total number of customers in each country (Geography)?
SELECT 
    Geography,
    COUNT(*) AS total_customers
FROM customers
GROUP BY Geography
ORDER BY total_customers DESC;

-- ======================= 3 ============================= --
-- What is the average credit score of all customers?  
SELECT 
    ROUND(AVG(CreditScore),2) AS average_credit_score
FROM customers;
-- OR --
SELECT
	ROUND(SUM(CreditScore)/COUNT(*),2) AS avg_credit_score
FROM customers;

-- ========================= 4 =========================== --
-- How many customers have exited (`Exited = 1`)?  
SELECT 
    COUNT(*) AS total_exited_customers
FROM customers
WHERE Exited = TRUE;

-- ============================ 5 ============================ --
-- Find the number of active members (`IsActiveMember = 1`).  
SELECT 
    COUNT(*) AS total_active_members
FROM customers
WHERE IsActiveMember = TRUE;

-- =================== Intermediate Questions =============== --
-- What is the average balance of customers who have churned versus those who haven’t?  
SELECT 
    Exited,
    ROUND(AVG(Balance),2) AS average_balance
FROM customers
GROUP BY Exited
ORDER BY Exited DESC;

-- What percentage of customers in each country (`Geography`) have churned?  
SELECT 
    Geography,
    ROUND((SUM(CASE WHEN Exited = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS churn_rate_percentage
FROM customers
GROUP BY Geography
ORDER BY churn_rate_percentage DESC;

-- . How does the number of products (`NumOfProducts`) affect churn rates?  
SELECT 
    NumOfProducts,
    ROUND((SUM(CASE WHEN Exited = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS churn_rate_percentage
FROM customers
GROUP BY NumOfProducts
ORDER BY NumOfProducts;

-- What is the age distribution of customers who are active members (`IsActiveMember = 1`)?
SELECT 
    CASE
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 55 THEN '46-55'
        WHEN Age BETWEEN 56 AND 65 THEN '56-65'
        WHEN Age > 65 THEN '66+'
        ELSE 'Unknown'
    END AS AgeGroup,
    COUNT(*) AS total_active_members
FROM customers
WHERE IsActiveMember = TRUE
GROUP BY AgeGroup
ORDER BY AgeGroup;

-- What is the age distribution of customers who have Churned (`Exited = TRUE`)?
SELECT 
    CASE
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 55 THEN '46-55'
        WHEN Age BETWEEN 56 AND 65 THEN '56-65'
        WHEN Age > 65 THEN '66+'
        ELSE 'Unknown'
    END AS AgeGroup,
    COUNT(*) AS total_churned_customers
FROM customers
WHERE Exited = TRUE
GROUP BY AgeGroup
ORDER BY AgeGroup;

-- Which gender (`Gender`) has the higher churn rate?  
SELECT 
    Gender,
    ROUND((SUM(CASE WHEN Exited = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS churn_rate_percentage
FROM customers
GROUP BY Gender
ORDER BY churn_rate_percentage DESC;

-- What are the top three factors contributing to customer churn?  
SELECT 
    'CreditScore' AS factor,
    AVG(CreditScore) FILTER (WHERE Exited = TRUE) AS churned_avg,
    AVG(CreditScore) FILTER (WHERE Exited = FALSE) AS retained_avg
FROM customers

UNION ALL

SELECT 
    'Age' AS factor,
    AVG(Age) FILTER (WHERE Exited = TRUE) AS churned_avg,
    AVG(Age) FILTER (WHERE Exited = FALSE) AS retained_avg
FROM customers

UNION ALL

SELECT 
    'Balance' AS factor,
    AVG(Balance) FILTER (WHERE Exited = TRUE) AS churned_avg,
    AVG(Balance) FILTER (WHERE Exited = FALSE) AS retained_avg
FROM customers

UNION ALL

SELECT 
    'EstimatedSalary' AS factor,
    AVG(EstimatedSalary) FILTER (WHERE Exited = TRUE) AS churned_avg,
    AVG(EstimatedSalary) FILTER (WHERE Exited = FALSE) AS retained_avg
FROM customers;

-- Calculate churn rate by categorical factors
SELECT 
    factor,
    category,
    ROUND((SUM(CASE WHEN Exited = TRUE THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS churn_rate_percentage
FROM (
    SELECT 'NumOfProducts' AS factor, CAST(NumOfProducts AS TEXT) AS category, Exited FROM customers
    UNION ALL
    SELECT 'Geography', Geography AS category, Exited FROM customers
    UNION ALL
    SELECT 'Gender', Gender AS category, Exited FROM customers
) factors
GROUP BY factor, category
ORDER BY factor, churn_rate_percentage DESC;

-- average tenure of customers who have churned, segmented by geography
SELECT 
    Geography,
    ROUND(AVG(Tenure), 2) AS average_tenure
FROM customers
WHERE Exited = TRUE
GROUP BY Geography
ORDER BY Geography;

-- build a profile of the "ideal customer" least likely to churn --
SELECT 
    ROUND(AVG(CreditScore), 2) AS avg_credit_score,
    ROUND(AVG(Age), 2) AS avg_age,
    ROUND(AVG(Balance), 2) AS avg_balance,
    ROUND(AVG(EstimatedSalary), 2) AS avg_estimated_salary,
    COUNT(*) FILTER (WHERE Gender = 'Male')::FLOAT / COUNT(*) * 100 AS male_percentage,
    COUNT(*) FILTER (WHERE Gender = 'Female')::FLOAT / COUNT(*) * 100 AS female_percentage,
    COUNT(*) FILTER (WHERE IsActiveMember = TRUE)::FLOAT / COUNT(*) * 100 AS active_member_percentage,
    Geography,
    ROUND(AVG(Tenure), 2) AS avg_tenure
FROM customers
WHERE Exited = FALSE
GROUP BY Geography
ORDER BY active_member_percentage DESC, avg_credit_score DESC;

-- Based on this data, the "ideal customer" least likely to churn is:

-- Gender: Male
-- Credit Score: 651-653
-- Age: Around 37 years old
-- Balance: Higher balances are better, particularly in Germany.
-- Estimated Salary: Around $98,000-$102,000
-- Activity: Active members have better retention.

















