-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab: 117
-- Class Day: Friday 10AM - 12PM

tee PT4_workings_21522611.out;
SHOW DATABASES;
USE dswork;

-- Task 1: Setting up the tables
-- Q1: download the tables and values
-- Q2: Run the tables and values
SOURCE pracTest4Tables_b.sql;
SOURCE pracTest4Values_b.sql;
-- Q3: Display the structure
SHOW TABLES;
SHOW COLUMNS FROM Faculty;
SHOW COLUMNS FROM Student;
SHOW COLUMNS FROM Activity;
SHOW COLUMNS FROM VolWork;

-- Task 2: Write SQL statements and do the following tasks
-- Q1: create a view named 'FacultyActivities' that displays the following information for each faculty: faculty name, faculty code, total estimated cost of voluntary activities of the faculty, total faculty contribution of voluntary activities of the faculty and the number of voluntary activities each faculty has offered. use approproate column headings in the view. The view's results should be displayed in ascending order according to the estimated cost of voluntary activities of the faculty. If any faculty offers no activities, the total estimated cost of voluntary activities should be shown as 'NULL'. Use this view to show information about faculties that offer no voluntary activities
DROP VIEW IF EXISTS FacultyActivities;
CREATE VIEW FacultyActivities AS
SELECT 
f.faculty_name AS faculty_name, 
f.faculty_code AS faculty_code,
SUM(a.est_cost) AS total_est_cost,
SUM(a.faculty_contribution) AS total_fac_contribution,
COUNT(a.activity_no) AS num_activities
FROM Activity a
RIGHT JOIN Faculty f ON a.faculty_code = f.faculty_code
GROUP BY f.faculty_name, f.faculty_code
ORDER BY IFNULL(SUM(a.est_cost),NULL) ASC;

SELECT * FROM FacultyActivities;
SELECT * FROM FacultyActivities WHERE num_activities = 0;

-- Q2: Write a stored procedure to insert information about a new activity into the 'Activity' table. The procedure should accept the six parameters: activity number, activity name, faculty sponsoring the activity, leader, priority, and the estimated cost of the activity. The following conditions must be implemented: (1) if the priority is less than one or more than five, set the priority to NULL. (2) Set the faculty cost contribution to zero for every new activity. Call the procedure with suitable values and demonstrate that it works as intented. Note: You may first examine the attributes of the 'Activity' table to familiarise yourself with the information stored in the table (attributes, data types, etc).
DROP PROCEDURE IF EXISTS addActivity;
DELIMITER //
CREATE PROCEDURE addActivity(
IN ano CHAR(6), 
IN aname VARCHAR(24), 
IN fcode CHAR(3),
IN lno CHAR(6), 
IN prio SMALLINT, 
IN cost DECIMAL(8,2)
)
BEGIN
-- (1) priority outside 1..5 -> store NULL
IF prio < 1 OR prio > 5 THEN
SET prio = NULL;
END IF;

-- (2) faculty_contribution is always 0 for a new activity
INSERT INTO Activity VALUES (ano, aname, fcode, lno, cost, 0, prio);
END //
DELIMITER ;

CALL addActivity('C03107', 'Clean Up Day', 'A04', '000029', 2, 1500);
SELECT * FROM Activity WHERE activity_no = 'C03107';

CALL addActivity('C03108', 'Book Drive', 'A02', '000011', 7, 800);
SELECT * FROM Activity WHERE activity_no = 'C03108';
SELECT * FROM Activity;

-- Q3: Modify the procedure created in Q2 above to calculate the total estimated cost of activities after inserting a new activity and make the total estimated cost of activities outside the procedure. Call the procedure with suitable values and display the total cost of projects outside the procedure (note: the calculated total estimated cost must be accessible outside the procedure.)
DROP PROCEDURE IF EXISTS addActivity;
DELIMITER //
CREATE PROCEDURE addActivity(
IN ano CHAR(6), 
IN aname VARCHAR(24), 
IN fcode CHAR(3),
IN lno CHAR(6), 
IN prio SMALLINT, 
IN cost DECIMAL(8,2),
OUT totcost DECIMAL(8,2)
)
BEGIN
-- (1) priority outside 1..5 -> store NULL
IF prio < 1 OR prio > 5 THEN
SET prio = NULL;
END IF;

-- (2) faculty_contribution is always 0 for a new activity
INSERT INTO Activity VALUES (ano, aname, fcode, lno, cost, 0, prio);
SELECT IFNULL(SUM(est_cost),0) INTO totcost FROM Activity;
END //
DELIMITER ;

SELECT IFNULL(SUM(est_cost),0) FROM Activity;
CALL addActivity('C03109', 'Charity Run', 'A03', '000020', 4, 2000, @totCost);
SELECT @totCost AS total_est_cost;
SELECT * FROM Activity WHERE activity_no = 'C03109';

-- Q4: Add a new column called 'total_cost' to the 'Faculty' table to indicate the total estimated cost of all voluntary activities of each faculty. Initially, set the 'total_cost' value of every faculty to zero. Then, create an appropriate trigger to update a faculty's 'total_cost' whenever the estimated cost of one of its activities updated.
ALTER TABLE Faculty ADD COLUMN total_cost DECIMAL(10,2) NULL;
SELECT * FROM Faculty;
UPDATE Faculty SET total_cost = 0 WHERE faculty_code IS NOT NULL;
SELECT * FROM Faculty;

DROP TRIGGER IF EXISTS after_activity_update;
DELIMITER //
CREATE TRIGGER after_activity_update
AFTER UPDATE ON Activity
FOR EACH ROW
BEGIN
UPDATE Faculty f
SET f.total_cost = (SELECT IFNULL(SUM(a.est_cost), 0) FROM Activity a WHERE a.faculty_code = f.faculty_code)
WHERE f.faculty_code = OLD.faculty_code OR f.faculty_code = NEW.faculty_code;
END //
DELIMITER ;

SELECT * FROM Activity;
SELECT * FROM Faculty;
-- Test 1: C03100 (A01) est_cost 10000 -> 12000
UPDATE Activity SET est_cost = 12000 WHERE activity_no = 'C03100';
SELECT * FROM Activity WHERE faculty_code = 'A01';
SELECT * FROM Faculty;
-- Expected: A01 total_cost = 12000 + 5000 + 500 = 17500.00; other faculties still 0.00

-- Test 2: C03107 (A04) est_cost 1500 -> 1000
SELECT * FROM Activity;
SELECT * FROM Faculty;
UPDATE Activity SET est_cost = 1000 WHERE activity_no = 'C03107';
SELECT * FROM Activity WHERE faculty_code = 'A04';
SELECT * FROM Faculty;
-- Expected: A04 total_cost = 1000.00; A01 still 17500.00; others 0.00

-- Test 3: C03101 (A02) est_cost 500 -> 700
SELECT * FROM Activity;
SELECT * FROM Faculty;
UPDATE Activity SET est_cost = 700 WHERE activity_no = 'C03101';
SELECT * FROM Activity WHERE faculty_code = 'A02';
SELECT * FROM Faculty;
-- Expected: A02 total_cost = 700 + 600 + 800 = 2100.00