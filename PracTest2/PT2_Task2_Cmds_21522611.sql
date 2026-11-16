-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab Class Date / Starting Time: Friday 10-12

-- Task 1
-- Q1: Run PracTest2Tables_2.sql in dswork database
SHOW DATABASES;
USE dswork;
SOURCE PracTest2Tables_2.sql;

-- Q2: Run PracTest2Values_2.sql
SOURCE PracTest2Values_2.sql;

-- Q3: Show the table structure of the newly created table
SHOW TABLES;
SHOW COLUMNS FROM Customer;

-- Q4: Shos all the rows of the newly created table
SELECT * FROM Customer;

-- Task 2
-- Q1: Show the first name, last name, suburb cide, and suburb name of the customer who are from suburb 6107, 6155, 6108, or 6147
SELECT first_name, last_name, suburb_code, suburb_name FROM Customer WHERE suburb_code IN ('6107', '6155', '6108', '6147');

-- Q2: Show the customer_id, first_name, address, and the deposit of the customer who have null values as the deposit. The address of a customer is a combination of house no, street name, suburb name, suburb code, and the state/area and must be showsn in a column named Address. The address must have a comma and space between house no, steet name, suburb name, suburb code, and the state/are (Example: 20, Lanconia Street, Bentley, 6102, WA)

SELECT 
customer_id, 
first_name,
CONCAT(house_no, ', ', street, ', ', suburb_name, ', ', suburb_code, ', ', state_name) AS Address,
deposit
FROM Customer
WHERE deposit IS NULL;

-- Q3: Show the customer_id, first_name, suburb_name, and birth data of the customer who have registered in the system from any suburb where the second letter of the suburb's name is "A" (other letters can be anything). The birth date must be shown in the format Wednesday, 6 Aug. The column of the birthdate should be named Birthday
SELECT
customer_id,
first_name,
suburb_name,
DATE_FORMAT(birth_date,'%W, %e %b') AS Birthday
FROM Customer
WHERE suburb_name LIKE '_A%';

-- Q4: Show the customer_id, first_name, birth_date, joined_date, and age (in years) as at 31 August 2026 for all customer whose age will be greater than or equal to 30 years on that date. Assume 365.25 days per year when calculating age. The age may be displayed as a decimal value (e.g., 34.56)
SELECT
customer_id,
first_name,
birth_date,
joined_date,
ROUND((DATEDIFF('2026-08-31',birth_date)/365.25),2) AS age
FROM Customer
WHERE ROUND((DATEDIFF('2026-08-31',birth_date)/365.25),2) >= 30;

-- Q5a: subsription fee increased by 12%
SELECT
customer_id,
first_name,
last_name,
ROUND(subscription_fee,0) AS OldSubscription,
ROUND((1.12 * subscription_fee),0) AS NewSubscription
FROM Customer;

-- Q5b: show Q5a only for new subscription fee >= 1800
SELECT
customer_id,
first_name,
last_name,
ROUND(subscription_fee,0) AS OldSubscription,
ROUND((1.12 * subscription_fee),0) AS NewSubscription
FROM Customer
WHERE ROUND((1.12 * subscription_fee),0) >= 1800;

