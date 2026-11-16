-- Q1: Create stored procedure called setProjCost (no parameters) that sets proj_cost in Dept to the total est_cost
-- of all projects of that department. A department with no project should get 0. Run it and display Dept.
DROP PROCEDURE IF EXISTS setProjCost;
DELIMITER //
CREATE PROCEDURE setProjCost()
    BEGIN
        UPDATE Dept d
        SET proj_cost = (
            SELECT IFNULL(SUM(p.est_cost),0)
            FROM Proj p
            WHERE p.dept_code = d.dept_code
        );
    END //
DELIMITER ;
CALL setProjCost();
SELECT * FROM Dept;

-- Q2: create a stored procedure called raiseSalary that takes a department code
-- and a percentage (IN parameters) and increases the salary of every
-- employee in that department by that percentage. Test it with A05 and 10%
DROP PROCEDURE IF EXISTS raiseSalary;
DELIMITER //
CREATE PROCEDURE raiseSalary(
    IN dcode CHAR(6),
    IN pct DECIMAL (5,2)
)
    BEGIN
        UPDATE Emp e
        SET salary = (1+pct) * salary
        WHERE dept_code = dept_code;
    END //
DELIMITER ;
CALL raiseSalary('A05', 10);
SELECT * FROM Emp WHERE dept_code='A05';

-- Q3: create stored procedure addEmp that inserts new employee.
-- All values are given as IN parameters. Add employee 000030 Jane Doe, A04,
-- joined 2025-03-01, salary 65000
DROP PROCEDURE IF EXISTS addEmp;
DELIMITER //
CREATE PROCEDURE addEmp(
    IN eno CHAR(6),
    IN fname VARCHAR(12),
    IN lname VARCHAR(15),
    IN dcode CHAR(3),
    IN jdate DATE,
    IN sal DECIMAL(8,2)
)
    BEGIN
        INSERT INTO Emp(emp_no, first_name, last_name, dept_code, joined_date, salary)
            VALUES(eno, fname, lname, dcode, jdate, sal);
    END //
DELIMITER;
CALL addEmp('000030', 'Jane', 'Doe', 'A04', '2025-03-01', 65000);
SELECT * FROM Emp WHERE emp_no = '000030';

-- Q4: Same as Q3 but the procedure (addEmp2) works out the next employee
-- number by itself (largest emp_no + 1) and uses today's date as joined date
DROP PROCEDURE IF EXISTS addEmp2
DELIMITER //
CREATE PROCEDURE addEmp2(
    IN fname VARCHAR(12),
    IN lname VARCHAR(15),
    IN dcode CHAR(3),
    IN sal DECIMAL(8,2)
)
    BEGIN
        DECLARE eno CHAR (6);
        SELECT LPAD(MAX(emp_no) + 1, 6, '0') INTO eno FROM Emp;
        INSERT INTO Emp(emp_no, first_name, last_name, dept_code, joined_date, salary)
            VALUES(eno, fname, lname, dcode, CURDATE(), sal);
    END //
DELIMITER ;
CALL addEmp2('Satria','Said','A04','70000');
SELECT * FROM Emp WHERE dept_code = 'A04';

-- Q5 : Create a stored procedure called countEmp that takes a department code (IN)
-- and returns the number of employee in that department (OUT)
-- Test it with A01 and display the result
DROP PROCEDURE IF EXISTS countEmp;
DELIMITER //
CREATE PROCEDURE countEmp(
    IN dcode CHAR(3),
    OUT cemp INT
)
    BEGIN
        SELECT COUNT(*) INTO cemp FROM Emp WHERE dept_code = dcode ;
    END//
DELIMITER ;
CALL countEmp('A01', @cemp);
SELECT @cEmp AS 'Number of Employee in A01';

-- Q6: Create a stored procedure called projSummary that takes a project numner (IN)
-- and returns the number of employees allocated and the total hours (two OUT)
-- parameter. Test it with C03100
DROP PROCEDURE IF EXISTS projSummary;
DELIMITER //
CREATE PROCEDURE projSummary(
    IN prono CHAR(6),
    OUT cemp INT,
    OUT thours DECIMAL(5,2)
)
    BEGIN
        SELECT COUNT(*), SUM(hours) INTO cemp, thours FROM ProjAllocation WHERE proj_no = prono;
    END//
DELIMITER ;
CALL projSummary('C03100');
SELECT @cemp, @thours AS 'Total Employee of the Selected Project', 'Total Hours of the Selected Project';

-- Q7: create a stored procedure called applyRaise that uses an INOUT parameter:
-- it takes an amount and a percentage and returns the increased amount
-- in the same variable
DROP PROCEDURE IF EXISTS applyRaise;
DELIMITER //
CREATE PROCEDURE applyRaise(
    INOUT salary DECIMAL(8,2),
    IN percent DECIMAL(5,2)
)
    BEGIN
        SET salary = salary * (1+percent);
    END //
DELIMITER ;
SET @sal = 50000;
CALL applyRaise(@sal, 10);
SELECT @sal AS 'New Salary';

-- Q8: create a stored procedure called assignProj that allocates an employee to
-- a project with a number of hours.
-- - if the hours are negative, store NULL instead.
-- - if the employee or the project does not exits, stop with an error message.
-- - if the employee is already on that project, stop with an error message.
-- Test with valid and invalid values
DROP PROCEDURE IF EXISTS assignProj;
DELIMITER //
CREATE PROCEDURE assignProj(
    IN empid CHAR(6),
    IN prono CHAR(6),
    IN hrs DECIMAL(5,2)
)

    BEGIN
    DECLARE err_msg VARCHAR(100);

    IF hrs < 0 THEN
        SET hrs = NULL;
    END IF;

    IF (empid NOT IN (SELECT emp_no FROM Emp WHERE emp_no = empid)) OR (prono NOT IN (SELECT proj_no FROM Proj WHERE proj_no = prono)) THEN
        SET err_msg = CONCAT('Employee ', empid, ' does not exits OR ', prono, ' does not exist');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
    END IF;

    IF (empid IN (SELECT emp_no FROM ProjAllocation WHERE prono = proj_no)) THEN
        SET err_msg = CONCAT('Employee ', empid, ' is already in ', prono);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
    END IF;

    INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours)
    VALUES (empid, prono, hrs);
    END//
DELIMITER ;
CALL assignProj('000020', 'C03107', 5);
CALL assignProj('000022', 'C03107', -3);
CALL assignProj('000027', 'C03102', 6);
CALL assignProj('000009', 'C03102', 6); -- emp_no 000009 is not in the Emp list

-- Q9: Add two columns to ProjAllocation: hrs_update DECIMAL(5,2) and inc_dec CHAR(3)
-- Create a stored procedure chgTotHrs that takes an employee number and
-- a new total number of hours. It compares the new total with the employee's
-- current total hours (over all projects) and stores the difference shared
-- equally over the employee's projects in hrs_update, and 'INC', 'DEC' or 'N/A'
-- in inc_dec. Test with employee 0000012 and 24 hours.
ALTER TABLE ProjAllocation
    ADD COLUMN hrs_update DECIMAL(5,2) NULL,
    ADD COLUMN inc_dec CHAR(3);
SHOW COLUMNS FROM ProjAllocation;

DROP PROCEDURE IF EXISTS chgTotHrs;
DELIMITER //
CREATE PROCEDURE chgTotHrs(
    IN empid CHAR(6),
    IN nthrs DECIMAL(5,2)
)
    BEGIN
        DECLARE tot_hrs DECIMAL(5,2);
        DECLARE tot_proj INT;

        SET tot_hrs = (SELECT SUM(proj_hours) FROM ProjAllocation WHERE emp_no = empid);
        SET tot_proj = (SELECT COUNT(*) FROM ProjAllocation WHERE emp_no = empid);

        IF tot_hrs = nthrs THEN
            UPDATE ProjAllocation
            SET hrs_update = 0, inc_dec = 'N/A'
            WHERE emp_no = empid;
        
        ELSEIF tot_hrs < nthrs THEN
            UPDATE ProjAllocation
            SET hrs_update = (nthrs - tot_hrs) / tot_proj, inc_dec = 'INC'
            WHERE emp_no = empid;
        
        ELSE
            UPDATE ProjAllocation
            SET hrs_update = (tot_hrs - nthrs) / tot_proj, inc_dec = 'DEC'
            WHERE emp_no = empid;
        END IF;
    END//
DELIMITER ;
SELECT emp_no, SUM(proj_hours), COUNT(*)
FROM ProjAllocation
WHERE emp_no = '000012'
GROUP BY proj_no;
CALL chgTotHrs('000012',20);
SELECT *
FROM ProjAllocation
WHERE emp_no = '000012';

-- Q10: Create a stored procedure called sumTo that uses a LOOP to add up the
-- numbers 1..n (IN n) and returns the total OUT
DROP PROCEDURE IF EXISTS sumTo;
DELIMITER //
CREATE PROCEDURE sumTo(
    IN num INT,
    OUT tot INT
)
    BEGIN
        DECLARE i INT DEFAULT 1;
        SET tot = 0;
        add_loop: LOOP
            IF i > num THEN
                LEAVE add_loop;
            END IF;
            SET tot = tot + i;
            SET i = i + 1;
        END LOOP add_loop;
    END//
DELIMITER ;
CALL sumTo(10, @t);
SELECT @t;

-- Q11: create a stored procedure called deptEmpList that uses a CURSOR to build
-- a comma separated list of the full names of employees in a given department
-- (IN) and returns it (OUT). Test with A03
DROP PROCEDURE IF EXISTS deptEmpList;
DELIMITER //
CREATE PROCEDURE deptEmpList(
    IN depno CHAR(3),
    OUT elist VARCHAR(9999)
)
    BEGIN
        -- VARIABLES
        DECLARE done INT DEFAULT 0;
        DECLARE fullName VARCHAR(30);
        -- CURSOR
        DECLARE curEmp CURSOR FOR
            SELECT CONCAT(first_name, ' ', last_name) FROM Emp WHERE dept_code = depno;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        SET eList = '';
        OPEN curEmp;
        get_emp: LOOP
            FETCH curEmp INTO fullName;
            IF done = 1 THEN
                LEAVE get_emp;
            END IF;
            IF eList = '' THEN
                SET elist = fullName;
            ELSE
                SET elist = CONCAT(eList, ', ', fullName);
            END IF;
        END LOOP get_emp;
        CLOSE curEmp;
    END//
DELIMITER ;
CALL deptEmpList('A03', @list);
SELECT @list AS 'A03 employes';

-- Q12: Create a stored procedure called fixInitialCost that uses a CURSOR to go
-- through every project with a NULL initial_cost and sets its initial_cost
-- to 10% of its est_cost. Return the number of projects changed (OUT)
DROP PROCEDURE IF EXISTS fixInitialCost;
DELIMITER //
CREATE PROCEDURE fixInitialCost(
    OUT changed INT
)
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
    END//
DELIMITER ;
SELECT proj_no, est_cost, initial_cost FROM Proj WHERE initial_cost IS NULL;
CALL fixInitialCost(@c);
SELECT @c AS 'Projects changed';
SELECT proj_no, est_cost, initial_cost FROM Proj WHERE proj_no IN ('C03100','C03103','C03104');

-- Q13: Create a stored function called empFullName that takes an employee number and
-- returns the full name. Use it in a SELECT showing each project and its leader.
-- NOTE: a function needs DETERMINISTIC or READ SQL DATA here, otherwise:
-- ERROR 1418 (HY000): This function has none of DETERMINISTIC, NO SQL, or READS SQL
DROP FUNCTION IF EXISTS empFullName;
DELIMITER //
CREATE FUNCTION empFullName(
        eno CHAR(6)
)
RETURNS VARCHAR(30)
READS SQL DATA
    BEGIN
        DECLARE fname VARCHAR(30);
        SELECT CONCAT(first_name, ' ', last_name) INTO fname
        FROM Emp WHERE emp_no = eno;
        RETURN fname;
    END//
DELIMITER ;
SELECT proj_no, proj_name, leader, empFullName(leader) AS 'Leader name'
FROM Proj;

-- Q14: Display all the stored procedures and functions you created, and the code of one.
SHOW PROCEDURE STATUS WHERE Db = 'dswork';
SHOW FUNCTION STATUS WHERE Db = 'dswork';
SHOW CREATE PROCEDURE assignProj;

--- TRIGGERS
-- RESET Dept.proj_cost so it is correct before the triggers start keeping it up to date
CALL setProjCost();
SELECT * FROM Dept;

-- Q1: Create a trigger after_proj_insert so that when a new project is inserted,
-- the proj_cost of its department is increased by the project's est_cost.
-- handle NULL values. Insert a new project for A04 and display Dept and Proj
DROP TRIGGER IF EXISTS after_proj_insert;
DELIMITER //
CREATE TRIGGER after_proj_insert
    AFTER INSERT ON Proj
    FOR EACH ROW
        BEGIN
            -- IFNULL: NULL + ANYTHING = NULL, so treat NULL as 0
        UPDATE Dept
        SET proj_cost = IFNULL(proj_cost, 0) + IFNULL(NEW.est_cost, 0)
        WHERE dept_code = NEW.dept_code;
        END//
DELIMITER ;
SELECT * FROM Proj;
INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
    VALUES ('C03108', 'Client Survey','A04','000018', 2500, 500, 2);
SELECT * FROM Proj WHERE proj_no = 'C03108';
SELECT * FROM Dept WHERE proj_no = 'C03108';

-- Q2: Create a trigger after_proj_update so that when a project's est_cost (or its
-- department) changes, Dept.proj_cost stays correct. Handle NULL VALUES
DROP TRIGGER IF EXISTS after_proj_update;
DELIMITER //
CREATE TRIGGER after_proj_update
    AFTER UPDATE ON Proj
    FOR EACH ROW
        BEGIN
            -- take the old cost off the old dept, add the new cost to the new dept
            -- works when the dept did not change too
            UPDATE Dept
            SET proj_cost = IFNULL(proj_cost, 0) - IFNULL(OLD.est_cost, 0)
            WHERE dept_code = OLD.dept_code;

            UPDATE Dept
            SET proj_cost = IFNULL(proj_cost, 0) + IFNULL(NEW.est_cost,0)
            WHERE dept_code = NEW.dept_code;
        END//
DELIMITER ;
SELECT * FROM Proj;
SELECT * FROM Dept;
UPDATE Proj SET est_cost = 3000 WHERE proj_no = 'C03108';
SELECT * FROM Proj;
SELECT * FROM Dept;
UPDATE Proj SET est_cost = NULL WHERE proj_no = 'C03108';
SELECT * FROM Proj;
SELECT * FROM Dept;
UPDATE Proj SET est_cost = 2500 WHERE proj_no = 'C03108';
SELECT * FROM Proj;
SELECT * FROM Dept;

-- Q3: create a trigger after_proj_delete so that when a project is deleted
-- Dept.proj_cost is reduced by its est_cost.
DROP TRIGGER IF EXISTS after_proj_delete;
DELIMITER //
CREATE TRIGGER after_proj_delete
    AFTER DELETE ON Proj
    FOR EACH ROW
        BEGIN
            UPDATE Dept
            SET proj_cost = IFNULL(proj_cost, 0) - IFNULL(OLD.est_cost,0)
            WHERE dept_code = OLD.dept_code;
        END//
DELIMITER ;
SELECT * FROM Proj;
SELECT * FROM Dept;
INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES ('C03109', 'Temp project','A04','000030',700, 100, 1);
SELECT * FROM Proj;
SELECT * FROM Dept;
DELETE FROM Proj WHERE proj_no = 'C03109';
SELECT * FROM Proj;
SELECT * FROM Dept;

-- Q4: Create triggers before_alloc_insert and before_alloc_update on ProjAllocation
-- that stop the change with an error message if proj_hours is negative or more
-- than 40. The message must show the bad value.
DROP TRIGGER IF EXISTS before_alloc_insert;
DELIMITER //

CREATE TRIGGER before_alloc_insert
    BEFORE INSERT ON ProjAllocation
    FOR EACH ROW
        BEGIN
            DECLARE err_msg VARCHAR(100);
            IF NEW.proj_hours < 0 OR NEW.proj_hours > 40 THEN
                SET err_msg = CONCAT('The hours ', NEW.proj_hours, ' must be between 0 and 40');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
            END IF;
        END//

DELIMITER ;

DROP TRIGGER IF EXISTS before_alloc_update;
DELIMITER //
CREATE TRIGGER before_alloc_update
    BEFORE UPDATE ON ProjAllocation
    FOR EACH ROW
        BEGIN
            DECLARE err_msg VARCHAR(100);
            IF NEW.proj_hours < 0 OR NEW.proj_hours > 40 THEN
                SET err_msg = CONCAT('The hours ', NEW.proj_hours, ' must be between 0 and 40');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
            END IF;
        END//
DELIMITER ;

SELECT * FROM ProjAllocation WHERE proj_no = 'C03108';
INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours) VALUES ('000030', 'C03108', 8);
UPDATE ProjAllocation SET proj_hours = 12 WHERE emp_no = '000030' AND proj_no = 'C03108';
SELECT * FROM ProjAllocation WHERE proj_no = 'C03108';

-- Q5: Create a trigger before_emp_salary that stops an UPDATE on Emp if the new
-- salary is lower than 50000
DROP TRIGGER IF EXISTS before_emp_salary;
DELIMITER //
CREATE TRIGGER before_emp_salary
    BEFORE UPDATE ON Emp
    FOR EACH ROW
        BEGIN
            DECLARE err_msg VARCHAR(100);
            IF NEW.salary < 50000 THEN
                SET err_msg = CONCAT('The new salary ', NEW.salary, ' cannot be lower than 50000');
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
            END IF;
        END//
DELIMITER ;
SELECT * FROM Emp;
UPDATE Emp SET salary = 56000 WHERE emp_no = '000015';
SELECT * FROM Emp;
UPDATE Emp SET salary = 45000 WHERE emp_no = '000015';

-- Q6: Create triggers before_proj_insert and before_proj_update that DO NOT give an error
-- but fix bad values instead
-- - initial_cost cannot be more than est_cost: on INSERT set it to est_cost
-- on UPDATE keep the old intial_cost
-- size cannot be less than 1: set it to 1
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
        END//
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
        END//
DELIMITER ;

SELECT * FROM Proj;
INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
    VALUES ('C03110','Open Day', 'A05','000026', 900, 5000, 0);
SELECT * FROM Proj;

UPDATE Proj SET initial_cost = 99999 WHERE proj_no = 'C03110';
SELECT * FROM Proj;
SELECT * FROM Dept WHERE dept_code = 'A05';

-- Q7: Create a trigger after_proj_insert_leader so that when a new project is inserted,
-- its leader is automatically allocated to it with 0 hours
DROP TRIGGER IF EXISTS after_proj_insert_leader;
DELIMITER //
CREATE TRIGGER after_proj_insert_leader
    AFTER INSERT ON Proj
    FOR EACH ROW
        BEGIN
            INSERT INTO ProjAllocation(emp_no, proj_no, proj_hours)
            VALUES(NEW.leader, NEW.proj_no, 0);
        END//
DELIMITER ;
SELECT * FROM Proj;
SELECT * FROM ProjAllocation;
SELECT * FROM Dept;
INSERT INTO Proj(proj_no, proj_name, dept_code, leader, est_cost, initial_cost, size)
VALUES('C03111', 'Coding Club', 'A03', '000020', 400, 50, 2);
SELECT * FROM Proj;
SELECT * FROM ProjAllocation;
SELECT * FROM Dept;