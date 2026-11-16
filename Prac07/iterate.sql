DELIMITER //
CREATE PROCEDURE doIterate(p1 INT)
BEGIN
	label1: LOOP
		SET p1 = p1 + 1;
		IF p1 = 10 THEN
			LEAVE label1;
		END IF;
	END LOOP label1;
	set @x = p1;
END //
DELIMITER ;
