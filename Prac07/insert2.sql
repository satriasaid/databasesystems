DELIMITER //
CREATE PROCEDURE insEmpDetails2(
	fname VARCHAR(12),
	midinit CHAR(1),
	lastname VARCHAR(15),
	workdept CHAR(3),
	salary DECIMAL(8,2)
)
	COMMENT 'insert new employee record but empno is automatic update'
	
	BEGIN
		DECLARE nextid CHAR(6);
		SELECT MAX(empno)+1 FROM Emp INTO nextid;
	
		INSERT INTO Emp(empno, firstname, midinit, lastname, workdept, salary, bonus)
		VALUES (nextid, fname, midinit, lastname, workdept, salary, 0);
	END
//	
DELIMITER ;

