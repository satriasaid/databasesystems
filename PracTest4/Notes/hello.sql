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

-- Q2: Write a stored procedure to insert information about a new activity into the 'Activity' table. The procedure should accept the six parameters: activity number, activity name, faculty sponsoring the activity, leader, priority, and the estimated cost of the activity. The following conditions must be implemented: (1) if the priority is less than one or more than five, set the priority to NULL. (2) Set the faculty cost contribution to zero for every new activity. Call the procedure with suitable values and demonstrate that it works as intented. Note: You may first examine the attributes of the 'Activity' table to familiarise yourself with the information stored in the table (attributes, data types, etc).

-- Q3: Modify the procedure created in Q2 above to calculate the total estimated cost of activities after inserting a new activity and make the total estimated cost of activities outside the procedure. Call the procedure with suitable values and display the total cost of projects outside the procedure (note: the calculated total estimated cost must be accessible outside the procedure.)

-- Q4: Add a new column called 'total_cost' to the 'Faculty' table to indicate the total estimated cost of all voluntary activities of each faculty. Initially, set the 'total_cost' value of every faculty to zero. Then, create an appropriate trigger to update a faculty's 'total_cost' whenever the estimated cost of one of its activities updated.