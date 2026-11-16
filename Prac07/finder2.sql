CREATE PROCEDURE countNumEmp2(
	IN dep CHAR(3)
)
	COMMENT 'count the number of employees in a given department with user defined variable.'
	SET @num = (
		SELECT COUNT(*) FROM Emp
		WHERE workdept = dep
	);
