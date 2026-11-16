-- Task 1: creating the back-end database
-- Q1
SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS company;
SHOW DATABASES;

-- Q2
USE company;
SOURCE rebuild.sql;
SHOW TABLES;

-- Task 2: Creating database connectivity in the front end