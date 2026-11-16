-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab Class: Friday 10-12
-- Date:
-- Start time:

/* =====================================================================
   PRACTICAL TEST 4 - PREDICTION SET 2 (more practice, different questions)
   Topics: Week 7 (stored procedures, functions, cursors)
           Week 8 (triggers, views, indexes)
   Tables: Dept, Emp, Proj, ProjAllocation (pracTest4Tables_2 / Values_2)

   This whole file runs with no errors and can be run again and again:
       cd ~/DBS/PracTest4/Notes
       mysql -u dsuser -p
       SOURCE PracTest4_Prediction_2.sql;
   Lines that are SUPPOSED to give an error are commented out with
   the real error message underneath.

   Task 5 at the bottom = DEBUGGING PRACTICE (broken code -> error -> fix).
   ===================================================================== */


-- =====================================================================
-- Task 1 (setup)
-- =====================================================================

-- Q1: Download pracTest4Tables_2.sql and pracTest4Values_2.sql and save them in the PracTest4 directory
-- DONE

-- Q2: Run pracTest4Tables_2.sql and pracTest4Values_2.sql
USE dswork;
-- child tables first, otherwise ERROR 3730 (Cannot drop table 'Dept' referenced by a foreign key)
DROP TABLE IF EXISTS ProjAllocation, Proj, Emp, Dept;
SOURCE pracTest4Tables_2.sql;
SOURCE pracTest4Values_2.sql;

-- Q3: Display the structure of each table and display all rows from each table
SHOW TABLES;
DESCRIBE Dept;                  -- DESCRIBE = same as SHOW COLUMNS FROM
DESCRIBE Emp;
DESCRIBE Proj;
DESCRIBE ProjAllocation;
SELECT * FROM Dept;
SELECT * FROM Emp;
SELECT * FROM Proj;
SELECT * FROM ProjAllocation;


-- =====================================================================
-- Task 2 (stored procedures and functions - Week 7)
-- =====================================================================

-- Q1: Create a stored procedure called showDeptEmp that takes a department code
--     and DISPLAYS the employee number, full name (in one column called
--     'Full Name') and salary of every employee in that department, highest
--     salary first. Test it with A02.
--     (A procedure can just run a SELECT - the result is shown when you CALL it.)
DROP PROCEDURE IF EXISTS showDeptEmp;
DELIMITER //
CREATE PROCEDURE showDeptEmp(IN dcode CHAR(3))
BEGIN
	SELECT emp_no, CONCAT(first_name, ' ', last_name) AS 'Full Name', salary
	FROM Emp
	WHERE dept_code = dcode
	ORDER BY salary DESC;
END //
DELIMITER ;

CALL showDeptEmp('A02');
-- Expected: 6 rows, Aati Awang 150000 first, John Geyer / Masatoshi Yoshimura 72000 last


-- Q2: Create a stored procedure called deptStats that takes a department code (IN)
--     and gives back the lowest, highest and average salary (3 OUT parameters).
--     The average must be rounded to 2 decimal places. Test with A01.
DROP PROCEDURE IF EXISTS deptStats;
DELIMITER //
CREATE PROCEDURE deptStats(
	IN  dcode  CHAR(3),
	OUT minSal DECIMAL(8,2),
	OUT maxSal DECIMAL(8,2),
	OUT avgSal DECIMAL(10,2)
)
BEGIN
	SELECT MIN(salary), MAX(salary), ROUND(AVG(salary), 2)
	INTO minSal, maxSal, avgSal
	FROM Emp
	WHERE dept_code = dcode;
END //
DELIMITER ;

CALL deptStats('A01', @mn, @mx, @av);
SELECT @mn AS 'Lowest', @mx AS 'Highest', @av AS 'Average';
-- Expected: 54000.00, 100000.00, 73875.00


-- Q3: Create a stored procedure called salaryBand that takes an employee number (IN)
--     and gives back (OUT) 'High' if the salary is 100000 or more, 'Medium' if it
--     is 70000 or more, otherwise 'Low'. If the employee does not exist give back
--     'Unknown'. Test with 000016, 000011, 000015 and 999999.
DROP PROCEDURE IF EXISTS salaryBand;
DELIMITER //
CREATE PROCEDURE salaryBand(IN eno CHAR(6), OUT band VARCHAR(10))
BEGIN
	DECLARE sal DECIMAL(8,2);
	SET sal = (SELECT salary FROM Emp WHERE emp_no = eno);   -- NULL if no such employee

	IF sal IS NULL THEN
		SET band = 'Unknown';
	ELSEIF sal >= 100000 THEN
		SET band = 'High';
	ELSEIF sal >= 70000 THEN
		SET band = 'Medium';
	ELSE
		SET band = 'Low';
	END IF;
END //
DELIMITER ;

CALL salaryBand('000016', @b1);
CALL salaryBand('000011', @b2);
CALL salaryBand('000015', @b3);
CALL salaryBand('999999', @b4);
SELECT @b1, @b2, @b3, @b4;
-- Expected: High, Medium, Low, Unknown
-- Order of IF matters: check the BIGGEST limit first. If you check >= 70000
-- first, 150000 also passes it and you get 'Medium' for everybody rich.


-- Q4: Create a stored procedure called countProj that takes an employee number (IN)
--     and a running total (INOUT). It adds the number of projects that employee
--     works on to the running total. Use it to get the total number of project
--     allocations of employees 000012, 000015 and 000016 together.
DROP PROCEDURE IF EXISTS countProj;
DELIMITER //
CREATE PROCEDURE countProj(IN eno CHAR(6), INOUT running INT)
BEGIN
	SET running = running + (SELECT COUNT(*) FROM ProjAllocation WHERE emp_no = eno);
END //
DELIMITER ;

SET @total = 0;                 -- must start at 0, NULL + 3 = NULL
CALL countProj('000012', @total);
CALL countProj('000015', @total);
CALL countProj('000016', @total);
SELECT @total AS 'Total allocations';
-- Expected: 3 + 3 + 2 = 8


-- Q5: Create a stored procedure called changeLeader that takes a project number
--     and a new leader (employee number). Stop with an error message if:
--     - the project does not exist
--     - the employee does not exist
--     - the employee is not in the same department as the project
--     Otherwise change the leader. Test it.
DROP PROCEDURE IF EXISTS changeLeader;
DELIMITER //
CREATE PROCEDURE changeLeader(IN pno CHAR(6), IN newLeader CHAR(6))
BEGIN
	DECLARE err_msg VARCHAR(100);
	DECLARE pdept CHAR(3);
	DECLARE edept CHAR(3);

	SET pdept = (SELECT dept_code FROM Proj WHERE proj_no = pno);
	SET edept = (SELECT dept_code FROM Emp  WHERE emp_no = newLeader);

	IF pdept IS NULL THEN
		SET err_msg = CONCAT('Project ', pno, ' does not exist');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	ELSEIF edept IS NULL THEN
		SET err_msg = CONCAT('Employee ', newLeader, ' does not exist');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	ELSEIF pdept <> edept THEN
		SET err_msg = CONCAT('Employee ', newLeader, ' is in ', edept, ' but project is in ', pdept);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	UPDATE Proj SET leader = newLeader WHERE proj_no = pno;
END //
DELIMITER ;

SELECT proj_no, dept_code, leader FROM Proj WHERE proj_no = 'C03104';
CALL changeLeader('C03104', '000017');
SELECT proj_no, dept_code, leader FROM Proj WHERE proj_no = 'C03104';
-- Expected: leader 000016 -> 000017
-- Error examples:
-- CALL changeLeader('X99999', '000017');
--   ERROR 1644 (45000): Project X99999 does not exist
-- CALL changeLeader('C03104', '999999');
--   ERROR 1644 (45000): Employee 999999 does not exist
-- CALL changeLeader('C03104', '000010');
--   ERROR 1644 (45000): Employee 000010 is in A01 but project is in A02


-- Q6: Create a stored procedure called deleteEmp that deletes an employee.
--     If the employee leads a project, do NOT delete and give an error message
--     showing how many projects they lead. Their project allocations must
--     disappear too (the FK has ON DELETE CASCADE). Test with 000027 and 000018.
DROP PROCEDURE IF EXISTS deleteEmp;
DELIMITER //
CREATE PROCEDURE deleteEmp(IN eno CHAR(6))
BEGIN
	DECLARE err_msg VARCHAR(100);
	DECLARE numLead INT;

	SET numLead = (SELECT COUNT(*) FROM Proj WHERE leader = eno);
	IF numLead > 0 THEN
		SET err_msg = CONCAT('Employee ', eno, ' leads ', numLead, ' project(s) and cannot be deleted');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	DELETE FROM Emp WHERE emp_no = eno;
END //
DELIMITER ;

SELECT * FROM ProjAllocation WHERE emp_no = '000027';
CALL deleteEmp('000027');
SELECT * FROM Emp WHERE emp_no = '000027';
SELECT * FROM ProjAllocation WHERE emp_no = '000027';
-- Expected: both empty (allocation C03102 removed by ON DELETE CASCADE)
-- Error examples:
-- CALL deleteEmp('000018');
--   ERROR 1644 (45000): Employee 000018 leads 2 project(s) and cannot be deleted
-- Without the check, MySQL itself stops it because Proj.leader has no CASCADE:
-- DELETE FROM Emp WHERE emp_no = '000018';
--   ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails ...


-- Q7: Create a stored procedure called transferEmp that moves an employee to a new
--     department and removes them from every project that does NOT belong to the
--     new department. Test by moving 000015 to A02.
DROP PROCEDURE IF EXISTS transferEmp;
DELIMITER //
CREATE PROCEDURE transferEmp(IN eno CHAR(6), IN newDept CHAR(3))
BEGIN
	UPDATE Emp SET dept_code = newDept WHERE emp_no = eno;

	DELETE FROM ProjAllocation
	WHERE emp_no = eno
	  AND proj_no IN (SELECT proj_no FROM Proj WHERE dept_code <> newDept);
END //
DELIMITER ;

SELECT pa.*, p.dept_code FROM ProjAllocation pa INNER JOIN Proj p ON pa.proj_no = p.proj_no
WHERE pa.emp_no = '000015';
CALL transferEmp('000015', 'A02');
SELECT emp_no, first_name, dept_code FROM Emp WHERE emp_no = '000015';
SELECT pa.*, p.dept_code FROM ProjAllocation pa INNER JOIN Proj p ON pa.proj_no = p.proj_no
WHERE pa.emp_no = '000015';
-- Expected: before C03100(A01), C03101(A02), C03104(A02); after only C03101, C03104


-- Q8: Create a stored procedure called raiseUntil that uses a LOOP to give an
--     employee 5% raises one at a time until the salary reaches a target. Give back
--     (OUT) how many raises were needed. Test with 000015 and 60000.
DROP PROCEDURE IF EXISTS raiseUntil;
DELIMITER //
CREATE PROCEDURE raiseUntil(IN eno CHAR(6), IN target DECIMAL(8,2), OUT numRaises INT)
BEGIN
	DECLARE sal DECIMAL(8,2);
	SET numRaises = 0;
	SET sal = (SELECT salary FROM Emp WHERE emp_no = eno);

	raise_loop: LOOP
		IF sal IS NULL OR sal >= target THEN   -- IS NULL check: stops an endless loop
			LEAVE raise_loop;
		END IF;
		SET sal = sal * 1.05;
		SET numRaises = numRaises + 1;
	END LOOP raise_loop;

	UPDATE Emp SET salary = sal WHERE emp_no = eno;
END //
DELIMITER ;

CALL raiseUntil('000015', 60000, @n);
SELECT @n AS 'Raises needed';
SELECT emp_no, salary FROM Emp WHERE emp_no = '000015';
-- Expected: 3 raises, 54000 -> 56700 -> 59535 -> 62511.75


-- Q9: Create a stored procedure called sumOdd that uses LOOP and ITERATE to add up
--     only the ODD numbers from 1 to n. Test with n = 10.
--     ITERATE = "skip the rest of this round, go back to the start of the loop"
--     LEAVE   = "get out of the loop completely"
DROP PROCEDURE IF EXISTS sumOdd;
DELIMITER //
CREATE PROCEDURE sumOdd(IN n INT, OUT total INT)
BEGIN
	DECLARE i INT DEFAULT 0;
	SET total = 0;
	odd_loop: LOOP
		SET i = i + 1;                 -- change i FIRST, or ITERATE loops forever
		IF i > n THEN
			LEAVE odd_loop;
		END IF;
		IF MOD(i, 2) = 0 THEN          -- even number -> skip it
			ITERATE odd_loop;
		END IF;
		SET total = total + i;
	END LOOP odd_loop;
END //
DELIMITER ;

CALL sumOdd(10, @s);
SELECT @s AS 'Sum of odd numbers';
-- Expected: 1+3+5+7+9 = 25


-- Q10: Create a stored procedure called addDeptToProj that uses a CURSOR to go
--      through every employee of a department and, if they are NOT already on the
--      given project, allocate them with the given hours. Give back (OUT) how many
--      were added. Test with department A03, project C03106, 4 hours.
DROP PROCEDURE IF EXISTS addDeptToProj;
DELIMITER //
CREATE PROCEDURE addDeptToProj(IN dcode CHAR(3), IN pno CHAR(6), IN hrs SMALLINT, OUT added INT)
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE eno CHAR(6);
	DECLARE curEmp CURSOR FOR
		SELECT emp_no FROM Emp WHERE dept_code = dcode;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	SET added = 0;
	OPEN curEmp;
	emp_loop: LOOP
		FETCH curEmp INTO eno;
		IF done = 1 THEN
			LEAVE emp_loop;
		END IF;
		IF (SELECT COUNT(*) FROM ProjAllocation WHERE emp_no = eno AND proj_no = pno) = 0 THEN
			INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours) VALUES (eno, pno, hrs);
			SET added = added + 1;
		END IF;
	END LOOP emp_loop;
	CLOSE curEmp;
END //
DELIMITER ;

SELECT * FROM ProjAllocation WHERE proj_no = 'C03106';
CALL addDeptToProj('A03', 'C03106', 4, @added);
SELECT @added AS 'Employees added';
SELECT * FROM ProjAllocation WHERE proj_no = 'C03106';
-- Expected: 2 added (000013 and 000020), 000018 and 000028 were already there


-- Q11: Add a column budget_status VARCHAR(10) to Proj. Create a stored procedure
--      called setBudgetStatus that uses a CURSOR to go through every project and sets:
--        'NONE' if initial_cost is NULL
--        'LOW'  if initial_cost is 20% of est_cost or less
--        'HIGH' otherwise
--      Give back (OUT) a list of the HIGH projects like 'C03105, C03107'.
ALTER TABLE Proj ADD COLUMN budget_status VARCHAR(10) NULL;

DROP PROCEDURE IF EXISTS setBudgetStatus;
DELIMITER //
CREATE PROCEDURE setBudgetStatus(OUT highList VARCHAR(500))
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE pno CHAR(6);
	DECLARE ecost DECIMAL(8,2);
	DECLARE icost DECIMAL(8,2);
	DECLARE curProj CURSOR FOR
		SELECT proj_no, est_cost, initial_cost FROM Proj;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	SET highList = '';
	OPEN curProj;
	proj_loop: LOOP
		FETCH curProj INTO pno, ecost, icost;    -- 3 columns -> 3 variables
		IF done = 1 THEN
			LEAVE proj_loop;
		END IF;

		IF icost IS NULL THEN
			UPDATE Proj SET budget_status = 'NONE' WHERE proj_no = pno;
		ELSEIF icost <= ecost * 0.20 THEN
			UPDATE Proj SET budget_status = 'LOW' WHERE proj_no = pno;
		ELSE
			UPDATE Proj SET budget_status = 'HIGH' WHERE proj_no = pno;
			IF highList = '' THEN
				SET highList = pno;
			ELSE
				SET highList = CONCAT(highList, ', ', pno);
			END IF;
		END IF;
	END LOOP proj_loop;
	CLOSE curProj;
END //
DELIMITER ;

CALL setBudgetStatus(@high);
SELECT @high AS 'HIGH projects';
SELECT proj_no, est_cost, initial_cost, budget_status FROM Proj;
-- Expected: HIGH = C03105, C03106, C03107 ; NONE = C03100, C03103, C03104 ; LOW = C03101, C03102


-- Q12: Create a stored FUNCTION called yearsWorked that takes an employee number and
--      returns how many full years they have worked (from joined_date to today).
--      Use it to display every employee with 5 or more years.
DROP FUNCTION IF EXISTS yearsWorked;
DELIMITER //
CREATE FUNCTION yearsWorked(eno CHAR(6))
RETURNS INT
READS SQL DATA                 -- without this: ERROR 1418
BEGIN
	DECLARE yrs INT;
	SELECT TIMESTAMPDIFF(YEAR, joined_date, CURDATE()) INTO yrs
	FROM Emp WHERE emp_no = eno;
	RETURN yrs;
END //
DELIMITER ;

SELECT emp_no, first_name, joined_date, yearsWorked(emp_no) AS 'Years'
FROM Emp
WHERE yearsWorked(emp_no) >= 5
ORDER BY joined_date;
-- Expected (in Oct 2026): 10 rows, everyone who joined in 2020 or earlier
-- 000010 = 9 years ... the 2020 people = 6 years. TIMESTAMPDIFF counts FULL years only.


-- Q13: Create a stored FUNCTION called deptHours that takes a department code and
--      returns the total project hours of all projects run by that department
--      (0 if none). Use it to display every department with its total hours.
DROP FUNCTION IF EXISTS deptHours;
DELIMITER //
CREATE FUNCTION deptHours(dcode CHAR(3))
RETURNS INT
READS SQL DATA
BEGIN
	RETURN (SELECT IFNULL(SUM(pa.proj_hours), 0)
	        FROM ProjAllocation pa
	        INNER JOIN Proj p ON pa.proj_no = p.proj_no
	        WHERE p.dept_code = dcode);
END //
DELIMITER ;

SELECT dept_code, dept_name, deptHours(dept_code) AS 'Total hours'
FROM Dept;


-- Q14: Show the code of one procedure, list all routines, then remove one.
SHOW CREATE PROCEDURE changeLeader;
SHOW PROCEDURE STATUS WHERE Db = 'dswork';
SHOW FUNCTION STATUS WHERE Db = 'dswork';
DROP PROCEDURE IF EXISTS sumOdd;
-- DROP PROCEDURE sumOdd;      -- without IF EXISTS, a 2nd time gives ERROR 1305 does not exist


-- =====================================================================
-- Task 3 (triggers - Week 8)
-- =====================================================================

-- Q1: Create a table EmpSalaryLog(log_id auto number, emp_no, old_salary,
--     new_salary, changed_on date-time). Create a trigger so that every time an
--     employee's salary CHANGES, a row is added to EmpSalaryLog.
--     (If the UPDATE does not change the salary, nothing is logged.)
DROP TABLE IF EXISTS EmpSalaryLog;
CREATE TABLE EmpSalaryLog(
	log_id     INT AUTO_INCREMENT,
	emp_no     CHAR(6),
	old_salary DECIMAL(8,2),
	new_salary DECIMAL(8,2),
	changed_on DATETIME,
	PRIMARY KEY(log_id)
);

DROP TRIGGER IF EXISTS after_emp_salary_log;
DELIMITER //
CREATE TRIGGER after_emp_salary_log
	AFTER UPDATE ON Emp
	FOR EACH ROW
BEGIN
	-- IFNULL so a change from/to NULL is also noticed (NULL <> 5 is NULL, not TRUE)
	IF IFNULL(OLD.salary, 0) <> IFNULL(NEW.salary, 0) THEN
		INSERT INTO EmpSalaryLog(emp_no, old_salary, new_salary, changed_on)
		VALUES (NEW.emp_no, OLD.salary, NEW.salary, NOW());
	END IF;
END //
DELIMITER ;

UPDATE Emp SET salary = salary * 1.10 WHERE dept_code = 'A05';
UPDATE Emp SET first_name = 'Ruchi' WHERE emp_no = '000017';   -- no salary change
SELECT * FROM EmpSalaryLog;
-- Expected: 2 rows: 000019 80000 -> 88000, 000026 110000 -> 121000 (nothing for 000017)


-- Q2: Create a table EmpArchive with the same columns as Emp plus deleted_on DATETIME.
--     Create a trigger that copies an employee into EmpArchive when they are deleted.
--     Test by deleting employee 000029.
DROP TABLE IF EXISTS EmpArchive;
CREATE TABLE EmpArchive(
	emp_no      CHAR(6),
	first_name  VARCHAR(12),
	last_name   VARCHAR(15),
	dept_code   CHAR(3),
	joined_date DATE,
	salary      DECIMAL(8,2),
	deleted_on  DATETIME
);

DROP TRIGGER IF EXISTS after_emp_delete_archive;
DELIMITER //
CREATE TRIGGER after_emp_delete_archive
	AFTER DELETE ON Emp
	FOR EACH ROW
BEGIN
	-- DELETE has only OLD (the row that was removed)
	INSERT INTO EmpArchive
	VALUES (OLD.emp_no, OLD.first_name, OLD.last_name, OLD.dept_code,
	        OLD.joined_date, OLD.salary, NOW());
END //
DELIMITER ;

DELETE FROM Emp WHERE emp_no = '000029';
SELECT * FROM Emp WHERE emp_no = '000029';
SELECT * FROM EmpArchive;
-- Expected: 000029 gone from Emp, Irving Stern now in EmpArchive


-- Q3: Create a trigger before_emp_insert so that when a new employee is inserted:
--     - a NULL joined_date becomes today's date
--     - a NULL salary becomes 50000
--     - a joined_date in the future gives an error
--     - first_name and last_name are saved with a capital first letter only (bonus)
DROP TRIGGER IF EXISTS before_emp_insert;
DELIMITER //
CREATE TRIGGER before_emp_insert
	BEFORE INSERT ON Emp
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);

	IF NEW.joined_date IS NULL THEN
		SET NEW.joined_date = CURDATE();
	ELSEIF NEW.joined_date > CURDATE() THEN
		SET err_msg = CONCAT('Joined date ', NEW.joined_date, ' cannot be in the future');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;

	IF NEW.salary IS NULL THEN
		SET NEW.salary = 50000;
	END IF;

	SET NEW.first_name = CONCAT(UPPER(LEFT(NEW.first_name, 1)), LOWER(SUBSTRING(NEW.first_name, 2)));
	SET NEW.last_name  = CONCAT(UPPER(LEFT(NEW.last_name, 1)),  LOWER(SUBSTRING(NEW.last_name, 2)));
END //
DELIMITER ;

INSERT INTO Emp(emp_no, first_name, last_name, dept_code) VALUES ('000040', 'mARY', 'jONES', 'A04');
SELECT * FROM Emp WHERE emp_no = '000040';
-- Expected: Mary Jones, A04, joined today, salary 50000.00
-- Error example:
-- INSERT INTO Emp VALUES ('000041', 'Tim', 'Lim', 'A04', '2099-01-01', 60000);
--   ERROR 1644 (45000): Joined date 2099-01-01 cannot be in the future


-- Q4: Create a trigger before_alloc_max so that an employee cannot be allocated to
--     more than 3 projects. The error message must show the employee and how many
--     projects they already have.
DROP TRIGGER IF EXISTS before_alloc_max;
DELIMITER //
CREATE TRIGGER before_alloc_max
	BEFORE INSERT ON ProjAllocation
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	DECLARE numProj INT;

	-- reading the SAME table in a trigger is fine, only CHANGING it is not allowed (1442)
	SET numProj = (SELECT COUNT(*) FROM ProjAllocation WHERE emp_no = NEW.emp_no);
	IF numProj >= 3 THEN
		SET err_msg = CONCAT('Employee ', NEW.emp_no, ' already has ', numProj, ' projects (max 3)');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;
END //
DELIMITER ;

SELECT emp_no, COUNT(*) FROM ProjAllocation WHERE emp_no IN ('000012', '000014') GROUP BY emp_no;
INSERT INTO ProjAllocation VALUES ('000014', 'C03107', 5);
SELECT * FROM ProjAllocation WHERE emp_no = '000014';
-- Expected: 000014 now on C03100 and C03107
-- Error example:
-- INSERT INTO ProjAllocation VALUES ('000012', 'C03107', 5);
--   ERROR 1644 (45000): Employee 000012 already has 3 projects (max 3)


-- Q5: Create a trigger before_proj_leader so that when a project's leader is CHANGED
--     by an UPDATE, the new leader must be in the same department as the project.
--     Updates that do not change the leader must still work.
DROP TRIGGER IF EXISTS before_proj_leader;
DELIMITER //
CREATE TRIGGER before_proj_leader
	BEFORE UPDATE ON Proj
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	DECLARE edept CHAR(3);

	IF NEW.leader <> OLD.leader THEN          -- only check when the leader changes
		SET edept = (SELECT dept_code FROM Emp WHERE emp_no = NEW.leader);
		IF edept <> NEW.dept_code THEN
			SET err_msg = CONCAT('Leader ', NEW.leader, ' is not in department ', NEW.dept_code);
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
		END IF;
	END IF;
END //
DELIMITER ;

UPDATE Proj SET leader = '000021' WHERE proj_no = 'C03104';     -- 000021 is in A02: OK
UPDATE Proj SET est_cost = 9000 WHERE proj_no = 'C03107';       -- leader 000018 (A03) not changed: OK
SELECT proj_no, dept_code, leader, est_cost FROM Proj WHERE proj_no IN ('C03104', 'C03107');
-- Without the "IF NEW.leader <> OLD.leader" the C03107 update would FAIL, because its
-- leader 000018 is already in the wrong department in the given data.
-- Error example:
-- UPDATE Proj SET leader = '000010' WHERE proj_no = 'C03104';
--   ERROR 1644 (45000): Leader 000010 is not in department A02


-- Q6: Add a column emp_count INT to Dept and fill it with the number of employees in
--     each department (0 if none). Create triggers on Emp to keep it correct when an
--     employee is inserted, deleted, or moved to another department.
--     The delete trigger must run AFTER after_emp_delete_archive (use FOLLOWS).
ALTER TABLE Dept ADD COLUMN emp_count INT NULL;

UPDATE Dept SET emp_count = 0;
UPDATE Dept d
INNER JOIN (SELECT dept_code, COUNT(*) AS cnt FROM Emp GROUP BY dept_code) e
	ON d.dept_code = e.dept_code
SET d.emp_count = e.cnt;
SELECT * FROM Dept;

DROP TRIGGER IF EXISTS after_emp_insert_count;
DELIMITER //
CREATE TRIGGER after_emp_insert_count
	AFTER INSERT ON Emp
	FOR EACH ROW
BEGIN
	UPDATE Dept SET emp_count = emp_count + 1 WHERE dept_code = NEW.dept_code;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS after_emp_update_count;
DELIMITER //
CREATE TRIGGER after_emp_update_count
	AFTER UPDATE ON Emp
	FOR EACH ROW
BEGIN
	IF NEW.dept_code <> OLD.dept_code THEN
		UPDATE Dept SET emp_count = emp_count - 1 WHERE dept_code = OLD.dept_code;
		UPDATE Dept SET emp_count = emp_count + 1 WHERE dept_code = NEW.dept_code;
	END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS after_emp_delete_count;
DELIMITER //
CREATE TRIGGER after_emp_delete_count
	AFTER DELETE ON Emp
	FOR EACH ROW
	FOLLOWS after_emp_delete_archive      -- two triggers on the same event: choose the order
BEGIN
	UPDATE Dept SET emp_count = emp_count - 1 WHERE dept_code = OLD.dept_code;
END //
DELIMITER ;

INSERT INTO Emp VALUES ('000041', 'Tim', 'Lim', 'A04', '2025-01-01', 60000);
SELECT dept_code, emp_count FROM Dept WHERE dept_code = 'A04';
-- Expected: A04 1 -> 2 (A04 already had Mary Jones from Q3)
UPDATE Emp SET dept_code = 'A05' WHERE emp_no = '000041';
SELECT dept_code, emp_count FROM Dept WHERE dept_code IN ('A04', 'A05');
-- Expected: A04 1, A05 3
DELETE FROM Emp WHERE emp_no = '000041';
SELECT dept_code, emp_count FROM Dept WHERE dept_code IN ('A04', 'A05');
SELECT emp_no, first_name FROM EmpArchive;
-- Expected: A05 2, and Tim Lim is also in EmpArchive (both delete triggers ran)
SHOW TRIGGERS LIKE 'Emp';
-- (Action_order column shows 1 for archive, 2 for count on the DELETE event)


-- =====================================================================
-- Task 4 (views and indexes - Week 8)
-- =====================================================================

-- Q1: Create a view called DeptSummary that shows for EVERY department (even with no
--     employees) the department code, name, number of employees, total salary and
--     average salary (2 decimals).
DROP VIEW IF EXISTS DeptSummary;
CREATE VIEW DeptSummary AS
	SELECT d.dept_code, d.dept_name,
	       COUNT(e.emp_no)                AS num_emp,       -- COUNT(e.emp_no) not COUNT(*): gives 0 for A04-type depts
	       IFNULL(SUM(e.salary), 0)       AS total_salary,
	       ROUND(IFNULL(AVG(e.salary), 0), 2) AS avg_salary
	FROM Dept d
	LEFT JOIN Emp e ON d.dept_code = e.dept_code              -- LEFT JOIN keeps depts with no employees
	GROUP BY d.dept_code, d.dept_name;

SELECT * FROM DeptSummary;


-- Q2: Create a view called EmpNoProject showing the employee number, full name and
--     department of employees who are not allocated to any project.
DROP VIEW IF EXISTS EmpNoProject;
CREATE VIEW EmpNoProject AS
	SELECT e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS full_name, e.dept_code
	FROM Emp e
	LEFT JOIN ProjAllocation pa ON e.emp_no = pa.emp_no
	WHERE pa.emp_no IS NULL;

SELECT * FROM EmpNoProject;
-- Same answer with a subquery:
-- SELECT emp_no FROM Emp WHERE emp_no NOT IN (SELECT emp_no FROM ProjAllocation);


-- Q3: Create a view called LeaderCount showing each project leader's number, full name
--     and how many projects they lead. Then create a view on that view called
--     MultiLeaders showing only leaders of more than one project.
DROP VIEW IF EXISTS MultiLeaders;      -- drop the view that USES LeaderCount first
DROP VIEW IF EXISTS LeaderCount;
CREATE VIEW LeaderCount AS
	SELECT e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS leader_name,
	       COUNT(p.proj_no) AS num_led
	FROM Emp e
	INNER JOIN Proj p ON e.emp_no = p.leader
	GROUP BY e.emp_no, e.first_name, e.last_name;

CREATE VIEW MultiLeaders AS
	SELECT * FROM LeaderCount WHERE num_led > 1;

SELECT * FROM LeaderCount;
SELECT * FROM MultiLeaders;
-- Expected MultiLeaders: 000018 Adrian Souza 2, 000021 Sally Kwan 2 (she got C03104 in Task 3 Q5)


-- Q4: Create a simple view ProjBudget (proj_no, proj_name, est_cost, initial_cost).
--     Update an est_cost THROUGH the view and show Proj changed. Then try to INSERT
--     through the view.
DROP VIEW IF EXISTS ProjBudget;
CREATE VIEW ProjBudget AS
	SELECT proj_no, proj_name, est_cost, initial_cost
	FROM Proj;

UPDATE ProjBudget SET est_cost = 700 WHERE proj_no = 'C03104';
SELECT * FROM ProjBudget WHERE proj_no = 'C03104';
SELECT proj_no, est_cost FROM Proj WHERE proj_no = 'C03104';
-- Expected: 700.00 in both (the view has no data of its own)
-- Error example: dept_code and leader are NOT NULL in Proj but are not in the view:
-- INSERT INTO ProjBudget VALUES ('C03199', 'New one', 100, 10);
--   ERROR 1423 (HY000): Field of view 'dswork.ProjBudget' underlying table doesn't have a default value


-- Q5: Change ProjBudget (without dropping it) so it also shows a column 'remaining'
--     = est_cost - initial_cost. Try to update 'remaining'.
CREATE OR REPLACE VIEW ProjBudget AS
	SELECT proj_no, proj_name, est_cost, initial_cost,
	       est_cost - initial_cost AS remaining
	FROM Proj;

SELECT * FROM ProjBudget;
-- remaining is NULL where initial_cost is NULL (NULL poisons maths)
-- Error example: a calculated column cannot be updated:
-- UPDATE ProjBudget SET remaining = 0 WHERE proj_no = 'C03105';
--   ERROR 1348 (HY000): Column 'remaining' is not updatable


-- Q6: Use EXPLAIN to show that searching Proj by proj_name reads the whole table.
--     Create an index to fix it and show EXPLAIN again. Then create a UNIQUE index on
--     Dept(dept_name) and show what happens when a duplicate name is inserted.
EXPLAIN SELECT * FROM Proj WHERE proj_name = 'Tax Clinic';
-- Before: type = ALL, key = NULL   (reads every row)
CREATE INDEX idx_proj_name ON Proj(proj_name);
EXPLAIN SELECT * FROM Proj WHERE proj_name = 'Tax Clinic';
-- After:  type = ref, key = idx_proj_name

CREATE UNIQUE INDEX idx_dept_name ON Dept(dept_name);
SHOW INDEX FROM Dept;
-- Error example: UNIQUE index does not allow the same value twice:
-- INSERT INTO Dept VALUES ('A06', 'Sales', NULL, 0);
--   ERROR 1062 (23000): Duplicate entry 'Sales' for key 'Dept.idx_dept_name'
-- A composite index (dept_code, salary) helps WHERE dept_code = ... (and dept_code + salary),
-- but NOT WHERE salary = ... alone (it must start from the LEFT column).


-- Q7: Show all views, then drop MultiLeaders and the proj_name index.
SHOW FULL TABLES WHERE Table_type = 'VIEW';
DROP VIEW IF EXISTS MultiLeaders;
DROP INDEX idx_proj_name ON Proj;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW INDEX FROM Proj;


-- =====================================================================
-- Task 5 (DEBUGGING PRACTICE)
-- Each broken code is commented out. Read it, guess the problem, then read the
-- error and the fix. The FIXED version under each one really runs.
-- =====================================================================

-- D1: semicolon inside the brackets + missing ; after CALL + missing FROM
--   CREATE PROCEDURE totalCost()
--   BEGIN
--       SELECT (SELECT SUM(est_cost) FROM Proj;) AS total;
--   END //
--   -> ERROR 1064 ... near ') AS total' : the ; ended the inner SELECT too early
--   CALL totalCost()
--   SELECT * Dept;
--   -> ERROR 1064 ... near 'SELECT * Dept' : no ; after CALL, and FROM is missing
-- FIX:
DROP PROCEDURE IF EXISTS totalCost;
DELIMITER //
CREATE PROCEDURE totalCost()
BEGIN
	SELECT (SELECT SUM(est_cost) FROM Proj) AS total;
END //
DELIMITER ;
CALL totalCost();
SELECT * FROM Dept;


-- D2: NO ERROR but WRONG RESULT - everybody gets a raise, and it is 11 times bigger
--   CREATE PROCEDURE badRaise(IN dcode CHAR(3), IN pct DECIMAL(5,2))
--   BEGIN
--       UPDATE Emp SET salary = (1 + pct) * salary
--       WHERE dept_code = dept_code;
--   END //
--   CALL badRaise('A05', 10);
--   Problem 1: "dept_code = dept_code" compares the column with ITSELF -> true for every row.
--              Compare with the PARAMETER: WHERE dept_code = dcode
--   Problem 2: pct is 10, so (1 + 10) * salary = 11 times the salary.
--              Use salary + salary * pct / 100   (or (1 + pct/100) * salary)
--   Tip: never give a parameter the same name as a column.
-- FIX:
DROP PROCEDURE IF EXISTS goodRaise;
DELIMITER //
CREATE PROCEDURE goodRaise(IN dcode CHAR(3), IN pct DECIMAL(5,2))
BEGIN
	UPDATE Emp SET salary = salary + salary * pct / 100
	WHERE dept_code = dcode;
END //
DELIMITER ;
SELECT emp_no, salary FROM Emp WHERE dept_code = 'A03';
CALL goodRaise('A03', 10);
SELECT emp_no, salary FROM Emp WHERE dept_code = 'A03';


-- D3: missing DELIMITER // at the start
--   CREATE PROCEDURE hello()
--   BEGIN
--       SELECT 'Hello';
--   -> ERROR 1064 ... near '' at line 3  (MySQL stopped at the first ;)
--   END //
--   -> the prompt now shows   ->   and waits. Type DELIMITER ; ... or start again with DELIMITER //
-- FIX:
DROP PROCEDURE IF EXISTS hello;
DELIMITER //
CREATE PROCEDURE hello()
BEGIN
	SELECT 'Hello';
END //
DELIMITER ;
CALL hello();


-- D4: misspelled local variable, and ELSE IF instead of ELSEIF
--   CREATE PROCEDURE grade(IN mark INT, OUT g CHAR(1))
--   BEGIN
--       DECLARE result CHAR(1);
--       IF mark >= 80 THEN
--           SET reslt = 'A';
--       ELSE IF mark >= 50 THEN
--           SET result = 'P';
--       ELSE
--           SET result = 'F';
--       END IF;
--       SET g = result;
--   END //
--   -> ERROR 1193 (HY000): Unknown system variable 'reslt'   (typo, not DECLAREd)
--   -> after fixing that: ERROR 1064 ... near '' : ELSE IF opens a NEW IF that never gets its own END IF
-- FIX:
DROP PROCEDURE IF EXISTS grade;
DELIMITER //
CREATE PROCEDURE grade(IN mark INT, OUT g CHAR(1))
BEGIN
	DECLARE result CHAR(1);
	IF mark >= 80 THEN
		SET result = 'A';
	ELSEIF mark >= 50 THEN
		SET result = 'P';
	ELSE
		SET result = 'F';
	END IF;
	SET g = result;
END //
DELIMITER ;
CALL grade(85, @g1);
CALL grade(60, @g2);
CALL grade(20, @g3);
SELECT @g1, @g2, @g3;
-- Expected: A, P, F


-- D5: cursor DECLARE in the wrong order, and FETCH into too few variables
--   CREATE PROCEDURE listProj(OUT pList VARCHAR(500))
--   BEGIN
--       DECLARE done INT DEFAULT 0;
--       DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
--       DECLARE cur CURSOR FOR SELECT proj_no, proj_name FROM Proj;
--       ...
--       FETCH cur INTO pno;
--   -> ERROR 1338 (42000): Cursor declaration after handler declaration
--      order must be: variables -> cursor -> handler
--   -> after fixing: ERROR 1328 (HY000): Incorrect number of FETCH variables
--      2 columns in the SELECT -> 2 variables in FETCH
-- FIX:
DROP PROCEDURE IF EXISTS listProj;
DELIMITER //
CREATE PROCEDURE listProj(OUT pList VARCHAR(500))
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE pno CHAR(6);
	DECLARE pname VARCHAR(24);
	DECLARE cur CURSOR FOR SELECT proj_no, proj_name FROM Proj;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	SET pList = '';                 -- if you forget this, pList stays NULL (CONCAT with NULL = NULL)
	OPEN cur;
	l: LOOP
		FETCH cur INTO pno, pname;
		IF done = 1 THEN
			LEAVE l;
		END IF;
		SET pList = CONCAT(pList, pno, ' ', pname, '; ');
	END LOOP l;
	CLOSE cur;
END //
DELIMITER ;
CALL listProj(@pl);
SELECT @pl;


-- D6: trigger that changes its own table, and NEW in an AFTER trigger
--   CREATE TRIGGER bad1 AFTER INSERT ON ProjAllocation FOR EACH ROW
--   BEGIN
--       UPDATE ProjAllocation SET proj_hours = 1 WHERE proj_hours IS NULL;
--   END //
--   -> creates fine, but the next INSERT gives
--      ERROR 1442 (HY000): Can't update table 'ProjAllocation' in stored function/trigger ...
--   CREATE TRIGGER bad2 AFTER INSERT ON ProjAllocation FOR EACH ROW
--   BEGIN
--       SET NEW.proj_hours = 1;
--   END //
--   -> ERROR 1362 (HY000): Updating of NEW row is not allowed in after trigger
-- FIX: BEFORE trigger + SET NEW.col
DROP TRIGGER IF EXISTS before_alloc_null_hours;
DELIMITER //
CREATE TRIGGER before_alloc_null_hours
	BEFORE INSERT ON ProjAllocation
	FOR EACH ROW
BEGIN
	IF NEW.proj_hours IS NULL THEN
		SET NEW.proj_hours = 1;
	END IF;
END //
DELIMITER ;
INSERT INTO ProjAllocation VALUES ('000020', 'C03107', NULL);
SELECT * FROM ProjAllocation WHERE emp_no = '000020';
-- Expected: C03106 4, C03107 1 (NULL became 1)


-- D7: OUT parameter called with a value, and wrong number of arguments
--   CALL deptStats('A01', 1, 2, 3);
--   -> ERROR 1414 (42000): OUT or INOUT argument 2 for routine dswork.deptStats is not a variable ...
--   CALL deptStats('A01', @mn);
--   -> ERROR 1318 (42000): Incorrect number of arguments for PROCEDURE dswork.deptStats; expected 4, got 2
--   SET x = (SELECT salary FROM Emp WHERE dept_code = 'A01');   (inside a procedure)
--   -> ERROR 1242 (21000): Subquery returns more than 1 row  (A01 has many employees)
-- FIX:
CALL deptStats('A01', @mn, @mx, @av);
SELECT @mn, @mx, @av;


/* =====================================================================
   NEW ERRORS IN THIS SET (all tested)
   1451 Cannot delete or update a parent row  -> a child row still points to it (no CASCADE)
   1423 Field of view ... doesn't have a default value -> INSERT via view missing NOT NULL cols
   1348 Column 'x' is not updatable            -> calculated column in a view
   1242 Subquery returns more than 1 row       -> SET x = (SELECT ...) found many rows
   1172 Result consisted of more than one row  -> SELECT ... INTO found many rows
   1362 Updating of NEW row is not allowed in after trigger -> use BEFORE
   1363 There is no OLD row in on INSERT trigger
   1060 Duplicate column name                  -> ALTER TABLE ADD COLUMN run twice
   1062 Duplicate entry ... for key 'Dept.idx_dept_name' -> UNIQUE index
   ===================================================================== */
