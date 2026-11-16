CREATE PROCEDURE countNumEmp(
	IN dep CHAR(3),
	OUT counter INT
)
	COMMENT 'count the number of employees in a given department.'
	SELECT COUNT(*) FROM Emp
	WHERE workdept = dep INTO counter;
