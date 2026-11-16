CREATE PROCEDURE insEmpDetails(
	eno CHAR(6),
	fname VARCHAR(12),
	midinit CHAR(1),
	lastname VARCHAR(15),
	workdept CHAR(3),
	salary DECIMAL(8,2)
)
	COMMENT 'insert new employee record'
	INSERT INTO Emp(empno, firstname, midinit, lastname, workdept, salary, bonus)
	VALUES (eno, fname, midinit, lastname, workdept, salary, 0);

