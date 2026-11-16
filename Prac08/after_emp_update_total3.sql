DELIMITER //

CREATE TRIGGER after_emp_update_total3
	AFTER UPDATE ON Emp1
	FOR EACH ROW
	BEGIN
		-- IF both old and new salaries are not null, then total salary needs to be added with the new salary and old salary difference
		IF OLD.salary IS NOT NULL
			AND NEW.salary IS NOT NULL THEN
				UPDATE Dept1
				SET total_sal = total_sal + NEW.salary - OLD.salary
				WHERE dept_no = NEW.dept_no;
		
		
		-- but if new salary is null, but the old salary is not null, reduce the total salary with the old salary
		ELSEIF (NEW.salary IS NULL AND OLD.salary IS NOT NULL)
			THEN
				UPDATE Dept1
				SET total_sal = total_sal - OLD.salary
				WHERE dept_no = OLD.dept_no;
		
		-- but if new salary is not null, but the old salary is null, then just add the new salary to the total salary
		ELSEIF (NEW.salary IS NOT NULL AND OLD.salary IS NULL)
			THEN
				UPDATE Dept1
				SET total_sal = total_sal + NEW.salary
				WHERE dept_no = NEW.dept_no;
		
		-- if both are null then total_salary is the same
		ELSE
			UPDATE Dept1
			SET total_sal = total_sal;
		END IF;
	END //

DELIMITER ;
