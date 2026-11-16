-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab Class Date / Starting Time: Friday 10-12

-- Task 3
-- Q1: create table based on the schema

CREATE TABLE Department(
        dept_id CHAR(4) PRIMARY KEY NOT NULL,
        d_name VARCHAR(40) NOT NULL);

CREATE TABLE Employee(
	emp_no CHAR(5) NOT NULL,
	check_digit CHAR(1) NOT NULL,
	first_name VARCHAR(40) NOT NULL,
	last_name VARCHAR(40) NOT NULL,
	dept_id CHAR(4) NOT NULL,
	PRIMARY KEY(emp_no, check_digit),
	CONSTRAINT fk_dept_id FOREIGN KEY(dept_id) REFERENCES Department(dept_id));

-- Q2: Run the statements using the created file and verify that the tables are created properly
-- SOURCE PT2_Task3_Cmds_21522611.sql;
SHOW TABLES;
SHOW COLUMNS FROM Employee;
SHOW COLUMNS FROM Department;

-- Q3: Add at least one tuple to each newly created table
INSERT INTO Department VALUES('0001', 'Department of Mysteries');
INSERT INTO Employee VALUES('00001', '5', 'Harry', 'Potter','0001');
SELECT * FROM Department;
SELECT * FROM Employee;
