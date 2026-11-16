/* MySQL file for creating tables for Practical-test4 */

-- create Dept table
DROP TABLE IF EXISTS Dept;
CREATE TABLE Dept(
            dept_code   		CHAR(3),
            dept_name		VARCHAR(36) NOT NULL,
            proj_cost        DECIMAL(10,2),
            PRIMARY KEY(dept_code)
);

-- create Employee table
DROP TABLE IF EXISTS Emp;
CREATE TABLE Emp(
        emp_no     	CHAR(6)	         ,
        first_name 	VARCHAR(12)      ,
        last_name  	VARCHAR(15)      ,
        dept_code 	CHAR(3)          ,
        joined_date   DATE         ,
        salary      DECIMAL(8,2)    ,
        PRIMARY KEY(emp_no),
        FOREIGN KEY(dept_code) REFERENCES Dept(dept_code)
);


-- create Project table

DROP TABLE IF EXISTS Proj;
CREATE TABLE Proj(
    proj_no		CHAR(6) NOT NULL,
    proj_name	VARCHAR(24) NOT NULL,
    dept_code      	CHAR(3) NOT NULL,
    leader		CHAR(6)	NOT NULL,
    est_cost   	DECIMAL(8,2),
    initial_cost 	DECIMAL(8,2),
    size	SMALLINT(6),
    PRIMARY KEY(proj_no),
    FOREIGN KEY(dept_code) REFERENCES Dept(dept_code),
    FOREIGN KEY(leader) REFERENCES Emp(emp_no)
);

-- create project allocation table
DROP TABLE IF EXISTS ProjAllocation;
CREATE TABLE ProjAllocation(
	emp_no     		CHAR(6),
	proj_no		    CHAR(6),
	proj_hours 		  	SMALLINT,
	PRIMARY KEY(emp_no,proj_no),
	FOREIGN KEY(emp_no) REFERENCES Emp(emp_no) ON DELETE CASCADE,
	FOREIGN KEY(proj_no) REFERENCES Proj(proj_no) ON DELETE CASCADE);
