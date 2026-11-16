DELIMITER //

CREATE TRIGGER before_emp_update_total
	BEFORE UPDATE ON Emp1
	FOR EACH ROW
	BEGIN
		DECLARE err_msg_less_24k VARCHAR(100);
		SET err_msg_less_24k = CONCAT('The new salary, ', NEW.salary, ' cannot be lower than 24000');
		IF NEW.salary < 24000 THEN
				SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = err_msg_less_24k;
		END IF;
	END//

CREATE TRIGGER before_emp_insert_total
	BEFORE INSERT ON Emp1
	FOR EACH ROW
	BEGIN
		DECLARE err_msg_less_24k VARCHAR(100);
		SET err_msg_less_24k = CONCAT('The new salary, ', NEW.salary, ' cannot be lower than 24000');
		IF NEW.salary < 24000 THEN
				SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = err_msg_less_24k;
		END IF;
	END//

DELIMITER ;
