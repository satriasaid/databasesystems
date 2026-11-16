DELIMITER //

CREATE PROCEDURE assignProj(
	eno CHAR(6),
	pno CHAR(6),
	hrs SMALLINT
)
BEGIN
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
