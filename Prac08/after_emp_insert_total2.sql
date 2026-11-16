DELIMITER //
CREATE TRIGGER after_emp_insert_total2
	AFTER INSERT ON Emp1
	FOR EACH ROW
		BEGIN
			IF NEW.salary IS NOT NULL THEN
				UPDATE Dept1
					SET total_sal = total_sal + NEW.salary
					WHERE dept_no = NEW.dept_no;
			END IF;
		END //
DELIMITER ;
