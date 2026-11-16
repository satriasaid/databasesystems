/* MySQL file for creating tables for Practical-test3 */
-- 2026 S2 Test E V2
-- create Faculty table
DROP TABLE IF EXISTS Faculty;
CREATE TABLE Faculty(
            faculty_code   		CHAR(3),
            faculty_name		VARCHAR(36) NOT NULL,
            PRIMARY KEY(faculty_code)
);

DROP TABLE IF EXISTS Building;
CREATE TABLE Building(
            building_num  CHAR(3),
            building_name	VARCHAR(36),
            building_type   VARCHAR(30),
            faculty_code  CHAR(3),
            building_rating CHAR(2),
            PRIMARY KEY(building_num),
            FOREIGN KEY(faculty_code ) REFERENCES Faculty(faculty_code) 
);

-- create Room table
DROP TABLE IF EXISTS Room;
CREATE TABLE Room(
        room_num   	CHAR(6),
        building_num  CHAR(3),
        capacity 	SMALLINT,
        room_type   CHAR(4),
        room_rating    CHAR(4),
        PRIMARY KEY(room_num, building_num),
        FOREIGN KEY(building_num) REFERENCES Building(building_num)
);

-- create Unit table
DROP TABLE IF EXISTS Unit;
CREATE TABLE Unit(
    unit_num		CHAR(8) NOT NULL,
    unit_name   	VARCHAR(24) NOT NULL,
    faculty_code    CHAR(3),
    unit_leader		VARCHAR(30)	NOT NULL,
    unit_level      CHAR(1),
    credits         SMALLINT,
    base_cost       DECIMAL(8,2),
    PRIMARY KEY(unit_num),
    FOREIGN KEY(faculty_code) REFERENCES Faculty(faculty_code)
);

-- create CommWork table
DROP TABLE IF EXISTS Class;
CREATE TABLE Class(
    class_id            CHAR(4) PRIMARY KEY,
    unit_num     		CHAR(8),
    room_num		    CHAR(6),
    building_num  CHAR(3),
    class_length	    SMALLINT,
    class_type          CHAR(4),
    FOREIGN KEY(room_num) REFERENCES Room(room_num),
    FOREIGN KEY(building_num) REFERENCES Room(building_num),
    FOREIGN KEY(unit_num) REFERENCES Unit(unit_num)
);
