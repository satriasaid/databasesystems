/* MySQL file for creating tables for Practical-test4 B 2026 S2 */

-- create Faculty table
DROP TABLE IF EXISTS Faculty;
CREATE TABLE Faculty(
            faculty_code   		CHAR(3),
            faculty_name		VARCHAR(36) NOT NULL,
            PRIMARY KEY(faculty_code)
);

-- create Students table
DROP TABLE IF EXISTS Student;
CREATE TABLE Student(
        stu_no     	CHAR(6)	         ,
        first_name 	VARCHAR(12)      ,
        last_name  	VARCHAR(15)      ,
        faculty_code  	CHAR(3)      ,
        reg_date   	DATE             ,
        comm_rate        CHAR(4)      ,
        PRIMARY KEY(stu_no),
        FOREIGN KEY(faculty_code) REFERENCES Faculty(faculty_code)
);


-- create Activity table

DROP TABLE IF EXISTS Activity;
CREATE TABLE Activity(
    activity_no		CHAR(6) NOT NULL,
    activity_name	VARCHAR(24) NOT NULL,
    faculty_code       	CHAR(3) NOT NULL,
    leader		CHAR(6)	NOT NULL,
    est_cost   	DECIMAL(8,2),
    faculty_contribution 	DECIMAL(8,2),
    priority	SMALLINT(6),
    PRIMARY KEY(activity_no),
    FOREIGN KEY(faculty_code) REFERENCES Faculty(faculty_code),
    FOREIGN KEY(leader) REFERENCES Student(stu_no)
);

-- create VolWork table
DROP TABLE IF EXISTS VolWork;
CREATE TABLE VolWork(
stu_no     		CHAR(6),
activity_no		CHAR(6),
hours 		      	SMALLINT,
PRIMARY KEY(stu_no,activity_no),
FOREIGN KEY(stu_no) REFERENCES Student(stu_no) ON DELETE CASCADE,
FOREIGN KEY(activity_no) REFERENCES Activity(activity_no) ON DELETE CASCADE);
