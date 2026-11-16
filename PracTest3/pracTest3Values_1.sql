/* MySQL code to insert values to tables created in PracTest 3*/
-- Insert values to Faculty table
INSERT INTO Faculty VALUES
('A01','Faculty of Science and Engineering');
INSERT INTO Faculty VALUES
('A02','Faculty of Humanities');
INSERT INTO Faculty VALUES
('A03','Faculty of Health Sceiences');
INSERT INTO Faculty VALUES
('A04','Faculty of Management');
INSERT INTO Faculty VALUES
('A05','Faculty of Law');

-- Insert values to building table 

INSERT INTO Building VALUES
('210','Engineering Technologies' , 'Lecture Theatres', 'A01',7); 
INSERT INTO Building VALUES
('211','Crop Labs' , 'Common', 'A03',6);  
INSERT INTO Building VALUES
('310','Science Labs' , 'labs', 'A03',4);  
INSERT INTO Building VALUES
('314','New Technologies' , 'Common', 'A01',2); 
 INSERT INTO Building VALUES
('200','Business School-Main' , 'Common', 'A04',7); 
INSERT INTO Building VALUES
('306','Temple Gardner Hall' , 'Lecture Theatres', 'A02',7);   
INSERT INTO Building VALUES
('501','The Forum' , 'Classrooms', 'A02',4);  
INSERT INTO Building VALUES
('505','Design Studio' , 'Classrooms', 'A01',4); 
 
-- Insert values into Room Table
INSERT INTO Room VALUES
('101', '314', 25 , 'CLAB', 6); 
INSERT INTO Room VALUES
('102', '314', 25 , 'CLAB', 6); 
INSERT INTO Room VALUES
('201', '314', 10 , 'SEMI', 7); 
INSERT INTO Room VALUES
('203', '314', 16, 'CLAB', 6); 
INSERT INTO Room VALUES
('205', '314', 16 , 'CLAB', 6; 
INSERT INTO Room VALUES
('301', '314', 12 , 'SEMI', 6); 
INSERT INTO Room VALUES
('441', '314', 3 , 'SEMI', 8); 
INSERT INTO Room VALUES
('105', '310', 24 , 'WLAB', 6); 
INSERT INTO Room VALUES
('106', '310', 24 , 'WLAB', 7); 
INSERT INTO Room VALUES
('107', '310', 24 ,'WLAB', 6); 
INSERT INTO Room VALUES
('102', '310', 50 , 'WLAB', 8); 
INSERT INTO Room VALUES
('201', '306', 110 , 'LECT', 6); 
INSERT INTO Room VALUES
('202', '306', 250, 'LECT', 8); 
INSERT INTO Room VALUES
('201', '210', 300 , 'LECT', 7); 
INSERT INTO Room VALUES
('202', '210', 500, 'LECT', 8); 
INSERT INTO Room VALUES
('303', '211', 24 , 'WLAB', 7); 
INSERT INTO Room VALUES
('302', '211', 24, 'WLAB', 6); 
INSERT INTO Room VALUES
('312', '211', 40, 'SEMI', 5); 
INSERT INTO Room VALUES
('313', '211', 30, 'SEMI', 7);
INSERT INTO Room VALUES
('202', '501', 40, 'SEMI', 8); 
INSERT INTO Room VALUES
('303', '501', 40 , 'SEMI', 7); 
INSERT INTO Room VALUES
('302', '501', 100, 'LECT', 6); 
INSERT INTO Room VALUES
('312', '501', 100, 'LECT', 5); 
INSERT INTO Room VALUES
('302', '501', 40 'CLAB', 7); 
INSERT INTO Room VALUES
('315', '501', 100, 'LECT', 5); 

-- Insert Values to UNit Table

INSERT INTO Unit VALUES
('COMP1001', 'Computing topics', 'A01', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('COMP1002', 'Programming Fundamentals', 'A01', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('CMPE3003', 'Computational Physics', 'A01', 'Victor Ray','3' , 25, 2500); 
INSERT INTO Unit VALUES
('MCAN4004', 'Engineering Drawing', 'A01', 'Mason Marriot','4' , 25, 2500); 
INSERT INTO Unit VALUES
('COMP1005', 'Requirement engineering', 'A01', 'ARaj Gopalan','1' , 25, 1500); 
INSERT INTO Unit VALUES
('BIOL1001', 'Microbiology - 1 ', 'A01', 'Jennifer Wilson','1' , 25, 1500); 
INSERT INTO Unit VALUES
('EDUC1001', 'Computing topics', 'A02', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('EDUC2001', 'Computing topics', 'A02', 'Sally Pham','2' , 25, 1500); 
INSERT INTO Unit VALUES
('COMM2022', 'Computing topics', 'A02', 'Sally Pham','3' , 25, 1500); 
INSERT INTO Unit VALUES
('PHAR1001', 'Computing topics', 'A03', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('PHAR2011', 'Computing topics', 'A03', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('PHSI2100', 'Computing topics', 'A03', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('PHSI1001', 'Computing topics', 'A03', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('BUSI2015', 'Computing topics', 'A04', 'Sally Pham','1' , 25, 1500); 
INSERT INTO Unit VALUES
('ISYS1001', 'Computing topics', 'A05', 'Sally Pham','1' , 25, 1500); 

-- insert valuse to Class Table
INSERT INTO Class Values
('1201', 'CMPE3003', '202', '306', 60 , 'LECT'); 
INSERT INTO Class Values
('1202', 'CMPE3003', '312', '211', 120 , 'SEMI'); 
INSERT INTO Class Values
('1203', 'BIOL1001', '303', '211', 60 , 'WLAB'); 

