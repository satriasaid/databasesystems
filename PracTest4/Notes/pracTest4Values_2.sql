/* MySQL code to insert values to tables created in PracTest 4*/
-- Insert values to Dept table
INSERT INTO Dept VALUES
('A01','Sales', NULL);
INSERT INTO Dept VALUES
('A02','Research and Development', NULL);
INSERT INTO Dept VALUES
('A03','Product Development', NULL);
INSERT INTO Dept VALUES
('A04','Client Services', NULL);
INSERT INTO Dept VALUES
('A05','People and Culture', 1000);

-- Insert values to Employees table
INSERT INTO Emp VALUES
('000010','Christine','Haas','A01','2017-02-10',100000);  
INSERT INTO Emp VALUES
('000011','John','Geyer','A02','2023-02-10',72000);
INSERT INTO Emp VALUES
('000012','Eva','Pulaski','A01','2019-02-10',82000); 
INSERT INTO Emp VALUES
('000013','Vincenzo','Lucchesi','A03','2018-02-10',75000); 
INSERT INTO Emp VALUES
('000014','Heather','Nicholls','A01','2019-02-10',60000); 
INSERT INTO Emp VALUES
('000015','Bruce','Adamson','A01','2020-02-10',54000); 
INSERT INTO Emp VALUES
('000016','Aati','Awang','A02','2023-02-10',150000); 
INSERT INTO Emp VALUES
('000017','Ruchira','Patel','A02','2023-02-10',120000); 
INSERT INTO Emp VALUES
('000018','Adrian','Souza','A03','2020-02-10',140000); 
INSERT INTO Emp VALUES
('000019','Diya','Chauhan','A05','2020-02-10',80000); 
INSERT INTO Emp VALUES
('000020','Apurva','Banerjee','A03','2022-02-10',65000); 
INSERT INTO Emp VALUES
('000021','Sally','Kwan','A02','2022-02-10',90000); 
INSERT INTO Emp VALUES
('000022','Masatoshi','Yoshimura','A02','2024-02-10',72000); 
INSERT INTO Emp VALUES
('000023','David','Brown','A01','2024-02-10',79000); 
INSERT INTO Emp VALUES
('000024','Salvatore','Marino','A01','2023-02-10',66000); 
INSERT INTO Emp VALUES
('000025','Ethel','Schneider','A01','2020-02-10',80000); 
INSERT INTO Emp VALUES
('000026','Daniel','Smith','A05','2019-02-10',110000); 
INSERT INTO Emp VALUES
('000027','John','Parker','A02','2020-02-10',90000); 
INSERT INTO Emp VALUES
('000028','Ying','Lee','A03','2020-02-10',90000); 
INSERT INTO Emp VALUES
('000029','Irving','Stern','A01','2022-02-10',70000); 

-- Insert values to Proj table
INSERT INTO Proj VALUES
('C03100','Science for kids','A01','000012',10000,NULL,NULL);
INSERT INTO Proj VALUES
('C03101','Daffodil day 2024','A02','000021',500,100,1);
INSERT INTO Proj VALUES
('C03102','Sci Fic with Schools','A01','000014',5000,1000,5);
INSERT INTO Proj VALUES
('C03103','Games Night -Sem1 ','A01','000015',500,NULL,3);
INSERT INTO Proj VALUES
('C03104','Lunch time music','A02','000016',600,NULL,1);
INSERT INTO Proj VALUES
('C03105','Tax Clinic','A05','000019',1200,600,3); 
INSERT INTO Proj VALUES
('C03106','Eating Healthy', 'A03','000018',8000,3000,3);  
INSERT INTO Proj VALUES
('C03107','Sustainability-2025', 'A02','000018',8000,2000,3);  

-- Insert values to ProjAllocation table 
INSERT INTO ProjAllocation VALUES('000014','C03100',6);
INSERT INTO ProjAllocation VALUES('000012','C03102',6);
INSERT INTO ProjAllocation VALUES('000016','C03103',6);
INSERT INTO ProjAllocation VALUES('000015','C03104',2);
INSERT INTO ProjAllocation VALUES('000019','C03105',6);
INSERT INTO ProjAllocation VALUES('000018','C03106',3);
INSERT INTO ProjAllocation VALUES('000012','C03101',2);
INSERT INTO ProjAllocation VALUES('000016','C03102',6);
INSERT INTO ProjAllocation VALUES('000015','C03100',4);
INSERT INTO ProjAllocation VALUES('000012','C03104',10);
INSERT INTO ProjAllocation VALUES('000023','C03106',8);
INSERT INTO ProjAllocation VALUES('000026','C03105',4);
INSERT INTO ProjAllocation VALUES('000027','C03102',10);
INSERT INTO ProjAllocation VALUES('000025','C03100',12);
INSERT INTO ProjAllocation VALUES('000028','C03106',9); 
INSERT INTO ProjAllocation VALUES('000021','C03101',6);
INSERT INTO ProjAllocation VALUES('000018','C03104',2);
INSERT INTO ProjAllocation VALUES('000015','C03101',3);
