DELIMITER //

CREATE TRIGGER before_pworks_insert_total
	BEFORE INSERT ON Pworks
	FOR EACH ROW
		BEGIN
			-- make sure that the new hours is not null and the employee is not in the current employee list. If the employee is not on the list, then add the employee count and total hours in Proj table
			IF NEW.hours IS NOT NULL AND NEW.empno NOT IN (SELECT DISTINCT empno FROM Pworks) THEN
				UPDATE Proj
					SET hrstotal = hrstotal + NEW.hours,
					empcnt = empcnt + 1
					WHERE projno = NEW.projno;
			END IF;
		END //
		
DELIMITER ;
