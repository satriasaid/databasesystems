DELIMITER //

CREATE TRIGGER before_pworks_update_total
	BEFORE UPDATE ON Pworks
	FOR EACH ROW
		BEGIN
			-- check if new hours is null and new empno is in employee list, then keep the employee count number but update total hours with the NEW and OLD hours
			IF NEW.hours IS NOT NULL AND NEW.empno NOT IN (SELECT DISTINCT empno FROM Pworks) THEN
				SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'empno does not exist, please check';
			END IF;
		END //

DELIMITER ;
