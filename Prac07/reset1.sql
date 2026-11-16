CREATE PROCEDURE resetEmpNewBonus()
	COMMENT 'set newBonus field to zero for all employees in the Emp table'
	UPDATE Emp
		SET newBonus = 0;
