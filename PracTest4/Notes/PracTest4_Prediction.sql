-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab Class: Friday 10-12
-- Date:
-- Start time:

/* =====================================================================
   PRACTICAL TEST 4 - PREDICTED QUESTIONS + TESTED ANSWERS
   Topics: Week 7 (stored procedures, functions, cursors)
           Week 8 (triggers, views, indexes)
   Tables: Dept, Emp, Proj, ProjAllocation (pracTest4Tables_2 / Values_2)

   This whole file runs with no errors and can be run again and again:
       cd ~/DBS/PracTest4/Notes
       mysql -u dsuser -p
       SOURCE PracTest4_Prediction.sql;
   Lines that are SUPPOSED to give an error are commented out with
   the error message shown underneath, so you can see what it looks like.

   Debugging cheat sheet is at the bottom of this file.
   ===================================================================== */


-- =====================================================================
-- Task 1 (setup - same every test)
-- =====================================================================

-- Q1: Download pracTest4Tables_2.sql and pracTest4Values_2.sql and save them in the PracTest4 directory
-- DONE

-- Q2: Run pracTest4Tables_2.sql and pracTest4Values_2.sql
USE dswork;
-- the tables file drops Dept first, which fails (FK error 3730) if Emp/Proj
-- already exist from an earlier run, so drop child tables first:
DROP TABLE IF EXISTS ProjAllocation, Proj, Emp, Dept;
SOURCE pracTest4Tables_2.sql;
SOURCE pracTest4Values_2.sql;

-- Q3: Display the structure of each table and display all rows from each table
SHOW TABLES;
SHOW COLUMNS FROM Dept;
SHOW COLUMNS FROM Emp;
SHOW COLUMNS FROM Proj;
SHOW COLUMNS FROM ProjAllocation;
SELECT * FROM Dept;
SELECT * FROM Emp;
SELECT * FROM Proj;
SELECT * FROM ProjAllocation;


-- =====================================================================
-- Task 2 (stored procedures - Week 7)
-- Pattern for EVERY procedure:
--   DROP PROCEDURE IF EXISTS name;
--   DELIMITER //
--   CREATE PROCEDURE name(...)
--   BEGIN
--       DECLARE ...   (all DECLAREs first: variables, then cursor, then handler)
--       statements;
--   END //
--   DELIMITER ;
--   CALL name(...);
--   SELECT ... to check it worked
-- =====================================================================

-- Q1: Create a stored procedure called setProjCost (no parameters) that sets
--     proj_cost in Dept to the total est_cost of all projects of that department.
--     A department with no projects should get 0. Run it and display Dept.
DROP PROCEDURE IF EXISTS setProjCost;
DELIMITER //
CREATE PROCEDURE setProjCost()
COMMENT 'Set Dept.proj_cost = total est_cost of the dept projects'
BEGIN
	UPDATE Dept d
	SET proj_cost = (SELECT IFNULL(SUM(p.est_cost), 0)
	                 FROM Proj p
	                 WHERE p.dept_code = d.dept_code);
END //
DELIMITER ;

CALL setProjCost();
SELECT * FROM Dept;
-- Expected: A01 15500.00, A02 9100.00, A03 8000.00, A04 0.00, A05 1200.00


-- Q2: Create a stored procedure called raiseSalary that takes a department code
--     and a percentage (IN parameters) and increases the salary of every
--     employee in that department by that percentage. Test it with A05 and 10%.
DROP PROCEDURE IF EXISTS raiseSalary;
DELIMITER //
CREATE PROCEDURE raiseSalary(IN dcode CHAR(3), IN pct DECIMAL(5,2))
BEGIN
	UPDATE Emp
	SET salary = salary + salary * pct / 100
	WHERE dept_code = dcode;
END //
DELIMITER ;

SELECT emp_no, first_name, salary FROM Emp WHERE dept_code = 'A05';
CALL raiseSalary('A05', 10);
SELECT emp_no, first_name, salary FROM Emp WHERE dept_code = 'A05';
-- Expected: 000019 80000 -> 88000.00, 000026 110000 -> 121000.00


-- Q3: Create a stored procedure called addEmp that inserts a new employee.
--     All values are given as IN parameters. Add employee 000030 Jane Doe, A04,
--     joined 2025-03-01, salary 65000.
DROP PROCEDURE IF EXISTS addEmp;
DELIMITER //
CREATE PROCEDURE addEmp(
	IN eno   CHAR(6),
	IN fname VARCHAR(12),
	IN lname VARCHAR(15),
	IN dcode CHAR(3),
	IN jdate DATE,
	IN sal   DECIMAL(8,2)
)
BEGIN
	INSERT INTO Emp(emp_no, first_name, last_name, dept_code, joined_date, salary)
	VALUES (eno, fname, lname, dcode, jdate, sal);
END //
DELIMITER ;

CALL addEmp('000030', 'Jane', 'Doe', 'A04', '2025-03-01', 65000);
SELECT * FROM Emp WHERE emp_no = '000030';
-- Error examples:
-- CALL addEmp('000030', 'Jane', 'Doe', 'A04', '2025-03-01', 65000);
--   ERROR 1062 (23000): Duplicate entry '000030' for key 'Emp.PRIMARY'
-- CALL addEmp('000099', 'Tom', 'Lee', 'Z99', '2025-03-01', 65000);
--   ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails


-- Q4: Same as Q3 but the procedure (addEmp2) works out the next employee
--     number by itself (largest emp_no + 1) and uses today's date as joined_date.
--     NOTE: MAX(emp_no)+1 gives 31 (a number), the leading zeros are lost,
--     so LPAD(..., 6, '0') puts them back -> '000031'.
DROP PROCEDURE IF EXISTS addEmp2;
DELIMITER //
CREATE PROCEDURE addEmp2(
	IN fname VARCHAR(12),
	IN lname VARCHAR(15),
	IN dcode CHAR(3),
	IN sal   DECIMAL(8,2)
)
BEGIN
	DECLARE nextno CHAR(6);
	SELECT LPAD(MAX(emp_no) + 1, 6, '0') INTO nextno FROM Emp;
	INSERT INTO Emp(emp_no, first_name, last_name, dept_code, joined_date, salary)
	VALUES (nextno, fname, lname, dcode, CURDATE(), sal);
END //
DELIMITER ;

CALL addEmp2('Kevin', 'Tran', 'A04', 70000);
SELECT * FROM Emp WHERE dept_code = 'A04';
-- Expected: 000030 Jane Doe and 000031 Kevin Tran


-- Q5: Create a stored procedure called countEmp that takes a department code (IN)
--     and returns the number of employees in that department (OUT).
--     Test it with A01 and display the result.
DROP PROCEDURE IF EXISTS countEmp;
DELIMITER //
CREATE PROCEDURE countEmp(IN dcode CHAR(3), OUT num INT)
BEGIN
	SELECT COUNT(*) INTO num
	FROM Emp
	WHERE dept_code = dcode;
END //
DELIMITER ;

CALL countEmp('A01', @num);
SELECT @num AS 'Employees in A01';
-- Expected: 8


-- Q6: Create a stored procedure called projSummary that takes a project number (IN)
--     and returns the number of employees allocated and the total hours (two OUT
--     parameters). Test it with C03100.
DROP PROCEDURE IF EXISTS projSummary;
DELIMITER //
CREATE PROCEDURE projSummary(IN pno CHAR(6), OUT numEmp INT, OUT totHrs INT)
BEGIN
	SELECT COUNT(*), IFNULL(SUM(proj_hours), 0) INTO numEmp, totHrs
	FROM ProjAllocation
	WHERE proj_no = pno;
END //
DELIMITER ;

CALL projSummary('C03100', @e, @h);
SELECT @e AS 'Number of employees', @h AS 'Total hours';
-- Expected: 3, 22
CALL projSummary('C03107', @e, @h);
SELECT @e AS 'Number of employees', @h AS 'Total hours';
-- Expected: 0, 0  (IFNULL stops it being NULL)


-- Q7: Create a stored procedure called applyRaise that uses an INOUT parameter:
--     it takes an amount and a percentage and returns the increased amount
--     in the same variable.
DROP PROCEDURE IF EXISTS applyRaise;
DELIMITER //
CREATE PROCEDURE applyRaise(INOUT amount DECIMAL(10,2), IN pct DECIMAL(5,2))
BEGIN
	SET amount = amount + amount * pct / 100;
END //
DELIMITER ;

SET @amt = 50000;
CALL applyRaise(@amt, 10);
SELECT @amt;
-- Expected: 55000.00


-- Q8: Create a stored procedure called assignProj that allocates an employee to
--     a project with a number of hours.
--     - If the hours are negative, store NULL instead.
--     - If the employee or the project does not exist, stop with an error message.
--     - If the employee is already on that project, stop with an error message.
--     Test with valid and invalid values.
DROP PROCEDURE IF EXISTS assignProj;
DELIMITER //
CREATE PROCEDURE assignProj(IN eno CHAR(6), IN pno CHAR(6), IN hrs SMALLINT)
BEGIN
	DECLARE err_msg VARCHAR(100);

	IF (SELECT COUNT(*) FROM Emp WHERE emp_no = eno) = 0 THEN
		SET err_msg = CONCAT('Employee ', eno, ' does not exist');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	IF (SELECT COUNT(*) FROM Proj WHERE proj_no = pno) = 0 THEN
		SET err_msg = CONCAT('Project ', pno, ' does not exist');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	IF (SELECT COUNT(*) FROM ProjAllocation WHERE emp_no = eno AND proj_no = pno) > 0 THEN
		SET err_msg = CONCAT('Employee ', eno, ' is already on project ', pno);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	IF hrs < 0 THEN
		SET hrs = NULL;
	END IF;

	INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours)
	VALUES (eno, pno, hrs);
END //
DELIMITER ;

CALL assignProj('000020', 'C03107', 5);
CALL assignProj('000022', 'C03107', -3);
SELECT * FROM ProjAllocation WHERE proj_no = 'C03107';
-- Expected: 000020 5, 000022 NULL
-- Error examples (these SHOULD fail):
-- CALL assignProj('999999', 'C03107', 5);
--   ERROR 1644 (45000): Employee 999999 does not exist
-- CALL assignProj('000020', 'X00000', 5);
--   ERROR 1644 (45000): Project X00000 does not exist
-- CALL assignProj('000020', 'C03107', 5);
--   ERROR 1644 (45000): Employee 000020 is already on project C03107

-- Alternative without SIGNAL (Prac07 assignproj2 style): label the BEGIN and LEAVE it
--   CREATE PROCEDURE assignProjB(IN eno CHAR(6), IN pno CHAR(6), IN hrs SMALLINT)
--   proc_label: BEGIN
--       IF (SELECT COUNT(*) FROM Emp WHERE emp_no = eno) = 0 THEN
--           SELECT 'Employee does not exist' AS Message;
--           LEAVE proc_label;
--       END IF;
--       ...
--   END proc_label //


-- Q9: Add two columns to ProjAllocation: hrs_update DECIMAL(5,2) and inc_dec CHAR(3).
--     Create a stored procedure called chgTotHrs that takes an employee number and
--     a new total number of hours. It compares the new total with the employee's
--     current total hours (over all projects) and stores the difference shared
--     equally over the employee's projects in hrs_update, and 'INC', 'DEC' or 'N/A'
--     in inc_dec. Test with employee 000012 and 24 hours.
ALTER TABLE ProjAllocation
	ADD COLUMN hrs_update DECIMAL(5,2) NULL,
	ADD COLUMN inc_dec CHAR(3) NULL;
SHOW COLUMNS FROM ProjAllocation;

DROP PROCEDURE IF EXISTS chgTotHrs;
DELIMITER //
CREATE PROCEDURE chgTotHrs(IN eno CHAR(6), IN new_hrs SMALLINT)
BEGIN
	DECLARE tot_hrs INT;
	DECLARE tot_proj INT;

	SET tot_hrs  = (SELECT SUM(proj_hours) FROM ProjAllocation WHERE emp_no = eno);
	SET tot_proj = (SELECT COUNT(*)        FROM ProjAllocation WHERE emp_no = eno);

	IF tot_hrs = new_hrs THEN
		UPDATE ProjAllocation
		SET hrs_update = 0, inc_dec = 'N/A'
		WHERE emp_no = eno;           -- the Prac07 version forgot this WHERE!
	ELSEIF tot_hrs < new_hrs THEN
		UPDATE ProjAllocation
		SET hrs_update = (new_hrs - tot_hrs) / tot_proj, inc_dec = 'INC'
		WHERE emp_no = eno;
	ELSE
		UPDATE ProjAllocation
		SET hrs_update = (tot_hrs - new_hrs) / tot_proj, inc_dec = 'DEC'
		WHERE emp_no = eno;
	END IF;
END //
DELIMITER ;

SELECT emp_no, SUM(proj_hours), COUNT(*) FROM ProjAllocation WHERE emp_no = '000012' GROUP BY emp_no;
CALL chgTotHrs('000012', 24);
SELECT * FROM ProjAllocation WHERE emp_no = '000012';
-- Expected: current total 18 over 3 projects -> each row hrs_update 2.00, INC
CALL chgTotHrs('000012', 12);
SELECT * FROM ProjAllocation WHERE emp_no = '000012';
-- Expected: each row hrs_update 2.00, DEC


-- Q10: Create a stored procedure called sumTo that uses a LOOP to add up the
--      numbers 1..n (IN n) and returns the total (OUT).
DROP PROCEDURE IF EXISTS sumTo;
DELIMITER //
CREATE PROCEDURE sumTo(IN n INT, OUT total INT)
BEGIN
	DECLARE i INT DEFAULT 1;
	SET total = 0;
	add_loop: LOOP
		IF i > n THEN              -- use > (not =) so it never loops forever
			LEAVE add_loop;
		END IF;
		SET total = total + i;
		SET i = i + 1;
	END LOOP add_loop;
END //
DELIMITER ;

CALL sumTo(10, @t);
SELECT @t;
-- Expected: 55
-- Infinite loop warning (Prac07 doIterate): IF p1 = 10 never true if you start at 10+.
-- If a CALL hangs, press Ctrl+C -> ERROR 1317 (70100): Query execution was interrupted


-- Q11: Create a stored procedure called deptEmpList that uses a CURSOR to build a
--      comma separated list of the full names of employees in a given department
--      (IN) and returns it (OUT). Test with A03.
DROP PROCEDURE IF EXISTS deptEmpList;
DELIMITER //
CREATE PROCEDURE deptEmpList(IN dcode CHAR(3), OUT eList VARCHAR(1000))
BEGIN
	-- order matters: variables, then cursor, then handler
	DECLARE done INT DEFAULT 0;
	DECLARE fullName VARCHAR(30);
	DECLARE curEmp CURSOR FOR
		SELECT CONCAT(first_name, ' ', last_name) FROM Emp WHERE dept_code = dcode;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	SET eList = '';
	OPEN curEmp;
	get_emp: LOOP
		FETCH curEmp INTO fullName;
		IF done = 1 THEN
			LEAVE get_emp;
		END IF;
		IF eList = '' THEN
			SET eList = fullName;
		ELSE
			SET eList = CONCAT(eList, ', ', fullName);
		END IF;
	END LOOP get_emp;
	CLOSE curEmp;
END //
DELIMITER ;

CALL deptEmpList('A03', @list);
SELECT @list AS 'A03 employees';
-- Expected: Vincenzo Lucchesi, Adrian Souza, Apurva Banerjee, Ying Lee


-- Q12: Create a stored procedure called fixInitialCost that uses a CURSOR to go
--      through every project with a NULL initial_cost and sets its initial_cost
--      to 10% of its est_cost. Return the number of projects changed (OUT).
DROP PROCEDURE IF EXISTS fixInitialCost;
DELIMITER //
CREATE PROCEDURE fixInitialCost(OUT changed INT)
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE pno CHAR(6);
	DECLARE ecost DECIMAL(8,2);
	DECLARE curProj CURSOR FOR
		SELECT proj_no, est_cost FROM Proj WHERE initial_cost IS NULL;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	SET changed = 0;
	OPEN curProj;
	proj_loop: LOOP
		FETCH curProj INTO pno, ecost;
		IF done = 1 THEN
			LEAVE proj_loop;
		END IF;
		UPDATE Proj SET initial_cost = ecost * 0.10 WHERE proj_no = pno;
		SET changed = changed + 1;
	END LOOP proj_loop;
	CLOSE curProj;
END //
DELIMITER ;

SELECT proj_no, est_cost, initial_cost FROM Proj WHERE initial_cost IS NULL;
CALL fixInitialCost(@c);
SELECT @c AS 'Projects changed';
SELECT proj_no, est_cost, initial_cost FROM Proj;
-- Expected: 3 changed -> C03100 1000.00, C03103 50.00, C03104 60.00 (10% of est_cost)


-- Q13: Create a stored FUNCTION called empFullName that takes an employee number and
--      returns the full name. Use it in a SELECT showing each project and its leader.
--      NOTE: a function needs DETERMINISTIC or READS SQL DATA here, otherwise:
--      ERROR 1418 (HY000): This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA ...
DROP FUNCTION IF EXISTS empFullName;
DELIMITER //
CREATE FUNCTION empFullName(eno CHAR(6))
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
	DECLARE fname VARCHAR(30);
	SELECT CONCAT(first_name, ' ', last_name) INTO fname
	FROM Emp WHERE emp_no = eno;
	RETURN fname;
END //
DELIMITER ;

SELECT proj_no, proj_name, leader, empFullName(leader) AS 'Leader name'
FROM Proj;


-- Q14: Display all the stored procedures and functions you created, and the code of one.
SHOW PROCEDURE STATUS WHERE Db = 'dswork';
SHOW FUNCTION STATUS WHERE Db = 'dswork';
SHOW CREATE PROCEDURE assignProj;


-- =====================================================================
-- Task 3 (triggers - Week 8)
-- Pattern for EVERY trigger:
--   DROP TRIGGER IF EXISTS name;
--   DELIMITER //
--   CREATE TRIGGER name
--       BEFORE|AFTER  INSERT|UPDATE|DELETE  ON Table
--       FOR EACH ROW
--   BEGIN
--       ... NEW.col (INSERT/UPDATE)   OLD.col (UPDATE/DELETE) ...
--   END //
--   DELIMITER ;
-- Then do the INSERT/UPDATE/DELETE and SELECT both tables to show it worked.
-- BEFORE = check/change the row (SET NEW.col = ..., SIGNAL error)
-- AFTER  = update ANOTHER table (totals, counts, logs)
-- =====================================================================

-- Reset Dept.proj_cost so it is correct before the triggers start keeping it up to date
CALL setProjCost();
SELECT * FROM Dept;

-- Q1: Create a trigger after_proj_insert so that when a new project is inserted,
--     the proj_cost of its department is increased by the project's est_cost.
--     Handle NULL values. Insert a new project for A04 and display Dept and Proj.
DROP TRIGGER IF EXISTS after_proj_insert;
DELIMITER //
CREATE TRIGGER after_proj_insert
	AFTER INSERT ON Proj
	FOR EACH ROW
BEGIN
	-- IFNULL: NULL + anything = NULL, so treat NULL as 0
	UPDATE Dept
	SET proj_cost = IFNULL(proj_cost, 0) + IFNULL(NEW.est_cost, 0)
	WHERE dept_code = NEW.dept_code;
END //
DELIMITER ;

INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES ('C03108', 'Client Survey', 'A04', '000030', 2500, 500, 2);
SELECT * FROM Proj WHERE proj_no = 'C03108';
SELECT * FROM Dept;
-- Expected: A04 0.00 -> 2500.00


-- Q2: Create a trigger after_proj_update so that when a project's est_cost (or its
--     department) changes, Dept.proj_cost stays correct. Handle NULL values.
DROP TRIGGER IF EXISTS after_proj_update;
DELIMITER //
CREATE TRIGGER after_proj_update
	AFTER UPDATE ON Proj
	FOR EACH ROW
BEGIN
	-- take the old cost off the old dept, add the new cost to the new dept
	-- (works when the dept did not change too)
	UPDATE Dept
	SET proj_cost = IFNULL(proj_cost, 0) - IFNULL(OLD.est_cost, 0)
	WHERE dept_code = OLD.dept_code;

	UPDATE Dept
	SET proj_cost = IFNULL(proj_cost, 0) + IFNULL(NEW.est_cost, 0)
	WHERE dept_code = NEW.dept_code;
END //
DELIMITER ;

UPDATE Proj SET est_cost = 3000 WHERE proj_no = 'C03108';
SELECT * FROM Dept;
-- Expected: A04 2500.00 -> 3000.00
UPDATE Proj SET est_cost = NULL WHERE proj_no = 'C03108';
SELECT * FROM Dept;
-- Expected: A04 0.00
UPDATE Proj SET est_cost = 2500 WHERE proj_no = 'C03108';
SELECT * FROM Dept;
-- Expected: A04 2500.00

-- Prac08 style (if they ask for the IF/ELSEIF NULL cases written out):
--   IF OLD.est_cost IS NOT NULL AND NEW.est_cost IS NOT NULL THEN
--       UPDATE Dept SET proj_cost = proj_cost + NEW.est_cost - OLD.est_cost WHERE dept_code = NEW.dept_code;
--   ELSEIF OLD.est_cost IS NOT NULL AND NEW.est_cost IS NULL THEN
--       UPDATE Dept SET proj_cost = proj_cost - OLD.est_cost WHERE dept_code = OLD.dept_code;
--   ELSEIF OLD.est_cost IS NULL AND NEW.est_cost IS NOT NULL THEN
--       UPDATE Dept SET proj_cost = proj_cost + NEW.est_cost WHERE dept_code = NEW.dept_code;
--   END IF;


-- Q3: Create a trigger after_proj_delete so that when a project is deleted,
--     Dept.proj_cost is reduced by its est_cost.
DROP TRIGGER IF EXISTS after_proj_delete;
DELIMITER //
CREATE TRIGGER after_proj_delete
	AFTER DELETE ON Proj
	FOR EACH ROW
BEGIN
	UPDATE Dept
	SET proj_cost = IFNULL(proj_cost, 0) - IFNULL(OLD.est_cost, 0)
	WHERE dept_code = OLD.dept_code;
END //
DELIMITER ;

INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES ('C03109', 'Temp project', 'A04', '000031', 700, 100, 1);
SELECT * FROM Dept WHERE dept_code = 'A04';
-- Expected: 3200.00
DELETE FROM Proj WHERE proj_no = 'C03109';
SELECT * FROM Dept WHERE dept_code = 'A04';
-- Expected: 2500.00


-- Q4: Create triggers before_alloc_insert and before_alloc_update on ProjAllocation
--     that stop the change with an error message if proj_hours is negative or more
--     than 40. The message must show the bad value.
DROP TRIGGER IF EXISTS before_alloc_insert;
DELIMITER //
CREATE TRIGGER before_alloc_insert
	BEFORE INSERT ON ProjAllocation
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	IF NEW.proj_hours < 0 OR NEW.proj_hours > 40 THEN
		SET err_msg = CONCAT('The hours, ', NEW.proj_hours, ', must be between 0 and 40');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS before_alloc_update;
DELIMITER //
CREATE TRIGGER before_alloc_update
	BEFORE UPDATE ON ProjAllocation
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	IF NEW.proj_hours < 0 OR NEW.proj_hours > 40 THEN
		SET err_msg = CONCAT('The hours, ', NEW.proj_hours, ', must be between 0 and 40');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;
END //
DELIMITER ;

INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours) VALUES ('000030', 'C03108', 8);
UPDATE ProjAllocation SET proj_hours = 12 WHERE emp_no = '000030' AND proj_no = 'C03108';
SELECT * FROM ProjAllocation WHERE proj_no = 'C03108';
-- Error examples (these SHOULD fail, the row is not changed):
-- INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours) VALUES ('000031', 'C03108', 50);
--   ERROR 1644 (45000): The hours, 50, must be between 0 and 40
-- UPDATE ProjAllocation SET proj_hours = -5 WHERE emp_no = '000030' AND proj_no = 'C03108';
--   ERROR 1644 (45000): The hours, -5, must be between 0 and 40


-- Q5: Create a trigger before_emp_salary that stops an UPDATE on Emp if the new
--     salary is lower than 50000 (Prac08 before_emp_upsert_error style).
DROP TRIGGER IF EXISTS before_emp_salary;
DELIMITER //
CREATE TRIGGER before_emp_salary
	BEFORE UPDATE ON Emp
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	IF NEW.salary < 50000 THEN
		SET err_msg = CONCAT('The new salary, ', NEW.salary, ' cannot be lower than 50000');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;
END //
DELIMITER ;

UPDATE Emp SET salary = 56000 WHERE emp_no = '000015';
SELECT emp_no, first_name, salary FROM Emp WHERE emp_no = '000015';
-- Error example:
-- UPDATE Emp SET salary = 30000 WHERE emp_no = '000015';
--   ERROR 1644 (45000): The new salary, 30000.00 cannot be lower than 50000


-- Q6: Create triggers before_proj_insert and before_proj_update that do NOT give an
--     error, but fix bad values instead (Prac08 ClassesInsertCheck style):
--     - initial_cost cannot be more than est_cost: on INSERT set it to est_cost,
--       on UPDATE keep the old initial_cost
--     - size cannot be less than 1: set it to 1
DROP TRIGGER IF EXISTS before_proj_insert;
DELIMITER //
CREATE TRIGGER before_proj_insert
	BEFORE INSERT ON Proj
	FOR EACH ROW
BEGIN
	IF NEW.initial_cost > NEW.est_cost THEN
		SET NEW.initial_cost = NEW.est_cost;
	END IF;
	IF NEW.size < 1 THEN
		SET NEW.size = 1;
	END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS before_proj_update;
DELIMITER //
CREATE TRIGGER before_proj_update
	BEFORE UPDATE ON Proj
	FOR EACH ROW
BEGIN
	IF NEW.initial_cost > NEW.est_cost THEN
		SET NEW.initial_cost = OLD.initial_cost;
	END IF;
	IF NEW.size < 1 THEN
		SET NEW.size = 1;
	END IF;
END //
DELIMITER ;

INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES ('C03110', 'Open Day', 'A05', '000026', 900, 5000, 0);
SELECT * FROM Proj WHERE proj_no = 'C03110';
-- Expected: initial_cost 900.00 (not 5000), size 1 (not 0)
UPDATE Proj SET initial_cost = 99999 WHERE proj_no = 'C03110';
SELECT * FROM Proj WHERE proj_no = 'C03110';
-- Expected: initial_cost still 900.00
SELECT * FROM Dept WHERE dept_code = 'A05';
-- Expected: 1200 + 900 = 2100.00 (after_proj_insert also fired)


-- Q7: Create a trigger after_proj_insert_leader so that when a new project is
--     inserted, its leader is automatically allocated to it with 0 hours
--     (Prac08 "insert into Pworks when a Proj is inserted" style).
DROP TRIGGER IF EXISTS after_proj_insert_leader;
DELIMITER //
CREATE TRIGGER after_proj_insert_leader
	AFTER INSERT ON Proj
	FOR EACH ROW
BEGIN
	INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours)
	VALUES (NEW.leader, NEW.proj_no, 0);
END //
DELIMITER ;

INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES ('C03111', 'Coding Club', 'A03', '000020', 400, 50, 2);
SELECT * FROM ProjAllocation WHERE proj_no = 'C03111';
-- Expected: 000020 C03111 0

-- IMPORTANT: drop it before Q8. Q8 adds a trigger on ProjAllocation that updates Proj.
-- Insert Proj -> this trigger inserts ProjAllocation -> that trigger updates Proj
-- = a trigger changing the table that fired it:
--   ERROR 1442 (HY000): Can't update table 'Proj' in stored function/trigger because
--   it is already used by statement which invoked this stored function/trigger.
DROP TRIGGER IF EXISTS after_proj_insert_leader;


-- Q8: Add two columns to Proj: emp_cnt INT and tot_hours INT. Fill them with the
--     number of employees and total hours from ProjAllocation (0 if none). Then
--     create triggers on ProjAllocation (after insert, after update, after delete)
--     to keep these two columns up to date. Handle NULL hours.
ALTER TABLE Proj
	ADD COLUMN emp_cnt INT NULL,
	ADD COLUMN tot_hours INT NULL;

-- start every project at 0, then fill in the ones that have allocations
UPDATE Proj SET emp_cnt = 0, tot_hours = 0;
UPDATE Proj p
INNER JOIN (SELECT proj_no, COUNT(*) AS cnt, IFNULL(SUM(proj_hours), 0) AS hrs
            FROM ProjAllocation
            GROUP BY proj_no) pa
	ON p.proj_no = pa.proj_no
SET p.emp_cnt = pa.cnt,
    p.tot_hours = pa.hrs;
SELECT proj_no, proj_name, emp_cnt, tot_hours FROM Proj;

DROP TRIGGER IF EXISTS after_alloc_insert;
DELIMITER //
CREATE TRIGGER after_alloc_insert
	AFTER INSERT ON ProjAllocation
	FOR EACH ROW
BEGIN
	UPDATE Proj
	SET emp_cnt = emp_cnt + 1,
	    tot_hours = tot_hours + IFNULL(NEW.proj_hours, 0)
	WHERE proj_no = NEW.proj_no;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS after_alloc_update;
DELIMITER //
CREATE TRIGGER after_alloc_update
	AFTER UPDATE ON ProjAllocation
	FOR EACH ROW
BEGIN
	UPDATE Proj
	SET tot_hours = tot_hours - IFNULL(OLD.proj_hours, 0) + IFNULL(NEW.proj_hours, 0)
	WHERE proj_no = NEW.proj_no;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS after_alloc_delete;
DELIMITER //
CREATE TRIGGER after_alloc_delete
	AFTER DELETE ON ProjAllocation
	FOR EACH ROW
BEGIN
	UPDATE Proj
	SET emp_cnt = emp_cnt - 1,
	    tot_hours = tot_hours - IFNULL(OLD.proj_hours, 0)
	WHERE proj_no = OLD.proj_no;
END //
DELIMITER ;

-- test insert, update, delete and show Proj each time
SELECT proj_no, emp_cnt, tot_hours FROM Proj WHERE proj_no = 'C03105';
-- Expected: 2, 10
INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours) VALUES ('000010', 'C03105', 5);
SELECT proj_no, emp_cnt, tot_hours FROM Proj WHERE proj_no = 'C03105';
-- Expected: 3, 15
UPDATE ProjAllocation SET proj_hours = 9 WHERE emp_no = '000010' AND proj_no = 'C03105';
SELECT proj_no, emp_cnt, tot_hours FROM Proj WHERE proj_no = 'C03105';
-- Expected: 3, 19
DELETE FROM ProjAllocation WHERE emp_no = '000010' AND proj_no = 'C03105';
SELECT proj_no, emp_cnt, tot_hours FROM Proj WHERE proj_no = 'C03105';
-- Expected: 2, 10
-- The assignProj procedure from Task 2 also fires these triggers:
CALL assignProj('000029', 'C03105', 7);
SELECT proj_no, emp_cnt, tot_hours FROM Proj WHERE proj_no = 'C03105';
-- Expected: 3, 17
-- NOTE: ON DELETE CASCADE rows (deleting a Proj/Emp) do NOT fire ProjAllocation triggers.


-- Q9: Display all triggers, then show how to remove one.
SHOW TRIGGERS;
SHOW TRIGGERS LIKE 'Proj';
-- DROP TRIGGER before_emp_salary;   -- example (left commented so it stays for the views below)


-- =====================================================================
-- Task 4 (views and indexes - Week 8)
-- =====================================================================

-- Q1: Create a view called ProjDetails showing project number, project name,
--     department name, leader's full name and est_cost for every project.
DROP VIEW IF EXISTS BigProjects;   -- depends on ProjDetails, drop it first
DROP VIEW IF EXISTS ProjDetails;
CREATE VIEW ProjDetails AS
	SELECT p.proj_no, p.proj_name, d.dept_name,
	       CONCAT(e.first_name, ' ', e.last_name) AS leader_name,
	       p.est_cost
	FROM Proj p
	INNER JOIN Dept d ON p.dept_code = d.dept_code
	INNER JOIN Emp  e ON p.leader = e.emp_no;

SELECT * FROM ProjDetails;


-- Q2: Create a view on top of ProjDetails called BigProjects showing only
--     projects with est_cost of 5000 or more.
CREATE VIEW BigProjects AS
	SELECT proj_no, proj_name, leader_name, est_cost
	FROM ProjDetails
	WHERE est_cost >= 5000;

SELECT * FROM BigProjects;
-- Expected: C03100, C03102, C03106, C03107


-- Q3: Show that the views change when the base table changes: increase the
--     est_cost of C03104 to 6000, then display BigProjects again.
UPDATE Proj SET est_cost = 6000 WHERE proj_no = 'C03104';
SELECT * FROM BigProjects;
-- Expected: C03104 now appears


-- Q4: Create a view called EmpHours showing each employee's number, full name,
--     number of projects and total hours. (GROUP BY view - cannot be updated)
DROP VIEW IF EXISTS EmpHours;
CREATE VIEW EmpHours AS
	SELECT e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS full_name,
	       COUNT(pa.proj_no) AS num_proj,
	       IFNULL(SUM(pa.proj_hours), 0) AS total_hours
	FROM Emp e
	LEFT JOIN ProjAllocation pa ON e.emp_no = pa.emp_no
	GROUP BY e.emp_no, e.first_name, e.last_name;

SELECT * FROM EmpHours ORDER BY total_hours DESC;
-- Error example:
-- UPDATE EmpHours SET total_hours = 5 WHERE emp_no = '000012';
--   ERROR 1288 (HY000): The target table EmpHours of the UPDATE is not updatable


-- Q5: Create a view called SalesEmp showing emp_no, names and salary of employees
--     in A01 only. Update a salary THROUGH the view and show the base table changed.
--     WITH CHECK OPTION stops changes that would make the row leave the view.
DROP VIEW IF EXISTS SalesEmp;
CREATE VIEW SalesEmp AS
	SELECT emp_no, first_name, last_name, dept_code, salary
	FROM Emp
	WHERE dept_code = 'A01'
	WITH CHECK OPTION;

UPDATE SalesEmp SET salary = 62000 WHERE emp_no = '000014';
SELECT * FROM SalesEmp WHERE emp_no = '000014';
SELECT emp_no, salary FROM Emp WHERE emp_no = '000014';
-- Error examples:
-- UPDATE SalesEmp SET dept_code = 'A02' WHERE emp_no = '000014';
--   ERROR 1369 (HY000): CHECK OPTION failed 'dswork.SalesEmp'
-- UPDATE SalesEmp SET salary = 40000 WHERE emp_no = '000014';
--   ERROR 1644 (45000): The new salary, 40000.00 cannot be lower than 50000  (trigger still fires)


-- Q6: Display all the views and the code of one view.
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW CREATE VIEW BigProjects;
-- CREATE OR REPLACE VIEW name AS ...   changes a view without dropping it first


-- Q7: Create an index on Emp(last_name) and a composite index on
--     ProjAllocation(proj_no, proj_hours). Show the indexes and use EXPLAIN to
--     show the index is used.
CREATE INDEX idx_emp_lastname ON Emp(last_name);
CREATE INDEX idx_alloc_proj_hrs ON ProjAllocation(proj_no, proj_hours);
SHOW INDEX FROM Emp;
SHOW INDEX FROM ProjAllocation;
EXPLAIN SELECT * FROM Emp WHERE last_name = 'Smith';
-- look at the 'key' column: idx_emp_lastname
EXPLAIN SELECT proj_no, proj_hours FROM ProjAllocation WHERE proj_no = 'C03100';
-- Remove an index:
DROP INDEX idx_emp_lastname ON Emp;
SHOW INDEX FROM Emp;


/* =====================================================================
   DEBUGGING CHEAT SHEET (MySQL error -> what it means -> fix)
   =====================================================================
   1064 You have an error in your SQL syntax ... near 'X'
        -> look JUST BEFORE 'X'. Common causes:
           - forgot DELIMITER // before CREATE PROCEDURE/TRIGGER
             (then MySQL stops at the first ; inside BEGIN)
           - forgot ; after END IF / END LOOP / a statement inside BEGIN
           - END IF written as ENDIF, ELSEIF written as ELSE IF
           - missing comma between parameters or columns
           - typo like PROCEDURES, TRIGERS
           - ended with END; instead of END //  (while delimiter is //)
   1046 No database selected            -> USE dswork;
   1146 Table 'dswork.x' doesn't exist   -> spelling / case of table name, or not SOURCEd yet
   1054 Unknown column 'x'              -> spelling, or wrong table alias, or used NEW/OLD wrong
   1193 Unknown system variable 'x'     -> SET on a name that is not DECLAREd
                                          (typo in local variable, or SET col = .. without UPDATE)
   1304 PROCEDURE x already exists      -> DROP PROCEDURE IF EXISTS x; first
   1359 Trigger already exists          -> DROP TRIGGER IF EXISTS x; first
   1305 PROCEDURE x does not exist      -> name typo, or created in another database
   1360 Trigger does not exist          -> name typo (SHOW TRIGGERS;)
   1318 Incorrect number of arguments   -> CALL has wrong number of values (OUT needs @var)
   1414 OUT or INOUT argument is not a variable -> CALL p(5) for OUT param; use CALL p(@x)
   1337 Variable or condition declaration after cursor or handler declaration
        -> DECLARE order: variables, then CURSOR, then HANDLER
   1338 Cursor declaration after handler declaration -> same fix
   1324 Undefined CURSOR / 1326 Cursor is not open -> OPEN it before FETCH
   1328 Incorrect number of FETCH variables -> FETCH into as many variables as SELECT columns
   1329 No data - zero rows fetched      -> missing CONTINUE HANDLER FOR NOT FOUND
   1418 function has none of DETERMINISTIC, NO SQL, READS SQL DATA
        -> add READS SQL DATA (or DETERMINISTIC) after RETURNS
   1442 Can't update table 'x' in stored function/trigger
        -> a trigger on table x cannot change table x (use BEFORE + SET NEW.col instead)
   1362 Updating of NEW row is not allowed in after trigger -> use BEFORE trigger
   1363 There is no OLD row in on INSERT trigger / no NEW row in on DELETE trigger
   1452 Cannot add or update a child row: foreign key fails -> parent value does not exist
   1062 Duplicate entry for key PRIMARY  -> that key is already used
   1048 Column 'x' cannot be null        -> NOT NULL column got NULL
   1288 The target table of the UPDATE is not updatable -> view has GROUP BY/COUNT/SUM/DISTINCT
   1369 CHECK OPTION failed              -> update would move the row out of the view
   1644 (45000) your own message         -> your SIGNAL worked (expected error)
   1055 isn't in GROUP BY                -> add every non-COUNT/SUM column to GROUP BY
   1317 Query execution was interrupted  -> you pressed Ctrl+C (infinite LOOP)
   3730 Cannot drop table referenced by a foreign key -> drop child tables first

   Useful commands while debugging:
   SHOW WARNINGS;  SHOW ERRORS;
   SHOW PROCEDURE STATUS WHERE Db = 'dswork';   SHOW CREATE PROCEDURE name;
   SHOW TRIGGERS;                               SHOW CREATE TRIGGER name;
   SHOW FULL TABLES WHERE Table_type = 'VIEW';  SHOW CREATE VIEW name;
   If the prompt shows  '>  or  ">  you have an unclosed quote: type the quote then ;
   If the prompt shows  ->  after END //  you forgot DELIMITER // at the start.
   After a CREATE with DELIMITER //, ALWAYS finish with DELIMITER ;
   Local variable (DECLARE x) only lives inside BEGIN..END, no @.
   User variable (@x) lives for the whole session, no DECLARE needed.
   ===================================================================== */
