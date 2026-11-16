DELIMITER //

CREATE PROCEDURE assignProj2alt(
	eno CHAR(6),
	pno CHAR(6),
	hrs SMALLINT
)
BEGIN
	-- CHECK IF THE empno added into the Pworks is in the Emp because the Pworks's empno is an FK based on Emp's empno.
	IF eno NOT IN (SELECT DISTINCT(empno) FROM Emp) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'The empno you were adding is not in our employee list yet';
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

END//

DELIMITER ;
