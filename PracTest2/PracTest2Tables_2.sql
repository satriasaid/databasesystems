
/* ParcTest2Tables_1.sql: SQL file for table creation in Practical test-2 */

-- create Students table

 CREATE TABLE Customer(
	customer_id CHAR(6),
    	first_name VARCHAR(12)  NOT NULL,
    	last_name VARCHAR(15)   NOT NULL,
	house_no VARCHAR(10), 		-- House number
	street VARCHAR(20), 		-- Street 
	suburb_name VARCHAR(20), 	-- Suburb code 
    	suburb_code CHAR(4),       -- Suburb name 
	state_name VARCHAR(20),     -- State/area	
	country VARCHAR(20),            
	phone_no CHAR(16),
	joined_date DATE,                  
	birth_date DATE,                  
	subscription_fee DECIMAL(8,2), 
	deposit  DECIMAL(8,2),         
	PRIMARY KEY(customer_id)
);

