-- ============================================================
-- UrbanMart Retail Operations Analysis
-- Stage 1: FETCH  -  "Get me the basic numbers"  (Q1-Q7)
-- Author: Satyabrata Sahoo | MySQL 8
-- ============================================================

USE urbanmart;

-- Q1. List all products priced above Rs 500 along with their category.
SELECT product_name, category, price
FROM products
WHERE price > 500;

-- Q2. Show all stores located in the "South" region.
SELECT *
FROM stores
WHERE region = 'South';

-- Q3. Get contact details of suppliers based in Mumbai.
SELECT supplier_name, contact_number, email
FROM suppliers
WHERE city = 'Mumbai';

-- Q4. Retrieve all employees working as "Sales Associate".
SELECT *
FROM employees
WHERE role = 'Sales Associate';

-- Q5. Show the 10 most recent transactions ordered by transaction_date.
--     transaction_id is a tie-breaker: 7 sales share 2024-01-28, so without it
--     the database may pick any 5 of them and the result changes between runs.
SELECT *
FROM transactions
ORDER BY transaction_date DESC, transaction_id DESC
LIMIT 10;

-- Q6. List all products under the "Electronics" category.
SELECT *
FROM products
WHERE category = 'Electronics';

-- Q7. Display all employees hired after 1st January 2023.
SELECT *
FROM employees
WHERE hire_date > '2023-01-01';
