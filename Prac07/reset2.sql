CREATE PROCEDURE resetEmpNewBonus2(IN val DECIMAL(8,2))
	COMMENT 'set newBonus asn an input (IN) parameter and assign that value to newBonus column for all employees'
	UPDATE Emp
		SET newBonus = val;
