DELIMITER //

CREATE PROCEDURE assignProj2(
	eno CHAR(6),
	pno CHAR(6),
	hrs SMALLINT
)
proc_label: BEGIN
	-- CHECK IF THE empno added into the Pworks is in the Emp because the Pworks's empno is an FK based on Emp's empno.
	IF eno NOT IN (SELECT DISTINCT(empno) FROM Emp) THEN
		SELECT 'The empno you were adding is not in the employee list' AS message;
		LEAVE proc_label;
	END IF;
		
	-- CHECK IF number of hours if not null is not negative.	
	IF hrs IS NOT NULL AND hrs < 0 THEN
		-- if negative, raise the custom error
		SELECT 'The number of hours work cannot be negative! Inserting NULL by default' AS message;
		INSERT INTO Pworks(empno, projno, hours)
		VALUES (eno, pno, NULL);
	ELSE
		INSERT INTO Pworks(empno, projno, hours)
		VALUES (eno, pno, hrs);
	END IF;

END proc_label//

DELIMITER ;
