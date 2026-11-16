DELIMITER //

CREATE PROCEDURE chgtotHrs(
	eno CHAR(6),
	new_hrs SMALLINT
)
BEGIN
	-- RETRIEVE EMPLOYEE'S TOTAL HOURS AND THE NUMBER OF PROJECTS THEY ARE ASSIGNED TO AND STORE THESE VALUES IN VARIABLE
	SET @tot_hrs = (
		SELECT SUM(hours) FROM Pworks
		WHERE empno = eno
	);
	
	SET @tot_proj = (
		SELECT COUNT(projno) FROM Pworks
		WHERE empno = eno
	);
	
	-- ADD THE UPDATED HOURS PER PROJECT AND WHETHER INCREASE OR DECREASE THE HOURS
	
	IF @tot_hrs = new_hrs THEN
		UPDATE Pworks
		SET hrsupdate = 0,
		increase_reduce = 'N/A';
	
	ELSEIF @tot_hrs < new_hrs THEN
		UPDATE Pworks
		SET hrsupdate = (new_hrs - @tot_hrs)/@tot_proj,
		increase_reduce = 'INC'
		WHERE empno = eno;
	
	ELSE
		UPDATE Pworks
		SET hrsupdate = (@tot_hrs - new_hrs)/@tot_proj,
		increase_reduce = 'DEC'
		WHERE empno = eno;
	END IF;
END //
DELIMITER ;
