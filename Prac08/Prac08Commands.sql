-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Class: 314.117
-- Session: Friday 10AM-12PM

-- Task 1: Trigger examples based on lecture slides.
-- Q1 -- create Emp1 and Dept1 tables
SHOW DATABASES;
USE dswork;

DROP TABLE IF EXISTS Dept;
CREATE TABLE Dept1(
            	dept_no   CHAR(3),
            	dept_name VARCHAR(36) NOT NULL,
            	total_sal    DECIMAL(8,2),
            	mgr    CHAR(6),
        	PRIMARY KEY(dept_no)
);

DROP TABLE IF EXISTS Emp1;
CREATE TABLE Emp1(
        emp_no     CHAR(6)	 	,
        name	  VARCHAR(40)           ,
        dept_no    CHAR(3)               ,
        salary    DECIMAL(8,2)          ,
        supervisor CHAR(6)	,
	PRIMARY KEY(emp_no),
        FOREIGN KEY(dept_no) REFERENCES Dept1(dept_no)
);

-- Q2 -- after employee is added to the database, we want to modify the total salary column of the department of that employee. We should create the trigger

SOURCE after_emp_insert_total2.sql

-- Q3 -- when the salary of an employee is changed, the total salary of their department must be modified
SOURCE after_emp_update_total2.sql

-- Q4 -- in Q3, the trigger works when both old salary and the new salary are NOT NULL. Revise the trigger code to make it works properly when either new salary is updated to null while old salary was NOT NULL OR when the old salary was null and it is updated to a new salary which is not a null value.
SOURCE after_emp_update_total3.sql

-- Q5 -- when an employee is removed, the total salary of the department has to be changed. Write AFTER DELETE TRIGGER
SOURCE after_emp_delete_total.sql

-- Q6 -- assume the salary cannot be less than $240000.00, add suitable before update and before insert triggers to enforce this constraint. show a suitable error message including the salary value when constraint is not satisfied
SOURCE before_emp_upsert_error.sql

-- Task 2: Triggers on employee database
-- Q1: add two attributes with suitable data types to the Proj table: emptcnt for recording the number of employees working on each project; hrstoal: for recording the total hrs to be spent on each project by all the employees
SOURCE rebuild.sql
ALTER TABLE Proj ADD COLUMN empcnt INT NULL, ADD COLUMN hrstotal DECIMAL(8,2) NULL;

-- Q2: update the values of the two new attributes in the Proj table based on information in the Pworks table
SELECT * FROM Proj;
SELECT * FROM Pworks;

UPDATE Proj pj
INNER JOIN (
	SELECT projno, COUNT(*) AS empcnt
	FROM Pworks
	GROUP BY projno
) AS pw ON pj.projno = pw.projno
SET pj.empcnt = pw.empcnt;

UPDATE Proj pj
INNER JOIN (
	SELECT projno, SUM(hours) AS hrstotal
	FROM Pworks
	GROUP BY projno
) AS pw ON pj.projno = pw.projno
SET pj.hrstotal = pw.hrstotal;

SELECT * FROM Proj;
SELECT * FROM Pworks;

-- Q3: write suitable triggers to maintain the attributes empcnt and hrstotal in the Proj table correctly, whenever the Pworks table is updated using insert, delete, or update operations. Test the triggers to verity whether they work correctly
SELECT * FROM Proj;
SELECT * FROM Pworks;

SOURCE after_pworks_update_total.sql

INSERT INTO Emp(empno, workdept) VALUES ('000341','E21');
INSERT INTO Pworks(empno, projno, hours) VALUES ('000341', 'OP2013', 20);
