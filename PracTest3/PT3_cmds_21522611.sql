-- Name: Satria Pamungkas
-- Student ID: 21522611
-- Lab Class: Friday 10-12

-- Task 1
-- Q1: Download Practest3Tables_1 and Practest3Values_1, save them in PracTest3 directory
-- DONE

-- Q2: Run Practest3Tables_1 and Practest3Values_1
USE dswork;
SOURCE pracTest3Tables_1.sql;
SOURCE pracTest3Values_1.sql;

--Q3: Display the structure of the newly added table and display all rows from each if the newly created tables
SHOW TABLES;
SHOW COLUMNS FROM Building;
SHOW COLUMNS FROM Class;
SHOW COLUMNS FROM Faculty;
SHOW COLUMNS FROM Room;
SHOW COLUMNS FROM Unit;
SELECT * FROM Building;
SELECT * FROM Class;
SELECT * FROM Faculty;
SELECT * FROM Room;
SELECT * FROM Unit;

-- Task 2
-- Q1: using appropriate join query, display the unit number, unit name, faculty code, class number, the room and the building number where the class is scheduled for all units belonging to the faculty with faculty code A01, for classes of type 'Lecture'
SELECT u.unit_num, u.unit_name, faculty_code, class_id, room_num, building_num
FROM Unit u
INNER JOIN Class c ON u.unit_num = c.unit_num 
WHERE faculty_code = 'A01' AND class_type = 'LECT';

-- Q2: Q1 but add faculty name
SELECT u.unit_num, u.unit_name, u.faculty_code, faculty_name, class_id, room_num, building_num
FROM Unit u
INNER JOIN Class c ON u.unit_num = c.unit_num 
INNER JOIN Faculty f ON u.faculty_code = f.faculty_code
WHERE u.faculty_code = 'A01' AND class_type = 'LECT';

-- Q3: using an appropriate join query, display the building number, room number, and room capacity of rooms with capacity greater than that of room 301 in building 314 excluding rooms in building 314. The results must be displayed in ascending order of room capacity. use appropriate aliases to display the column names of the resulting dataset
SELECT building_num AS 'Building No.', room_num AS 'Room No.', capacity AS 'Room Capacity'
FROM Room
WHERE capacity > (
SELECT capacity
FROM Room
WHERE room_num='301' AND building_num='314'
) AND building_num != '314'
ORDER BY capacity ASC;

-- Q4a. using an appropriate subquery, display the unique building numbers of buildings that have no classes scheduled in any of their rooms
SELECT DISTINCT(building_num)
FROM (
SELECT r.room_num, r.building_num, capacity, room_type, room_rating, class_id, unit_num, class_length, class_type
FROM Room r
LEFT JOIN Class c ON CONCAT(c.room_num,c.building_num) = CONCAT(r.room_num,r.building_num)
WHERE c.class_id IS NULL
) AS no_class_building;

-- Q4b. using appropriate subquery, display the building number, building name, and building rate of buildings that have no classes scheduled in them
SELECT building_num, building_name, building_rating
FROM (
SELECT r.room_num, r.building_num, capacity, room_type, room_rating, class_id, unit_num, class_length, class_type, building_name, building_rating
FROM Room r
LEFT JOIN Class c ON CONCAT(c.room_num,c.building_num) = CONCAT(r.room_num,r.building_num)
INNER JOIN Building b ON r.building_num = b.building_num
WHERE c.class_id IS NULL
) AS no_class_building;
