# PT4 Explained Simply

Stored procedures, functions, cursors, triggers, views and indexes, all explained with the PT4 tables (Dept, Emp, Proj, ProjAllocation).

---

## 1. The big picture

| Thing | What it is | Real-life picture | How it runs |
|---|---|---|---|
| Stored procedure | A saved set of SQL steps | A recipe card you can reuse | You run it with `CALL name();` |
| Stored function | Saved steps that give back ONE value | A calculator button | You use it inside a SELECT |
| Trigger | Steps that run by themselves when a table changes | A motion sensor light | Fires automatically on INSERT / UPDATE / DELETE |
| View | A saved SELECT that looks like a table | A window looking into tables | `SELECT * FROM viewname;` |
| Index | A lookup list that makes searching faster | The index at the back of a textbook | MySQL uses it by itself |

---

## 2. DELIMITER (the number one cause of errors)

Normally `;` means "run this now". A procedure has many `;` inside it, so MySQL would run it too early and break.

So we change the "run now" sign to `//` for a while, then change it back.

```sql
DELIMITER //              -- from now on, // means "run now"
CREATE PROCEDURE hello()
BEGIN
	SELECT 'Hi';          -- this ; does NOT run anything yet
END //                    -- NOW the whole procedure is sent
DELIMITER ;               -- put it back to normal
```

Rules to remember:
- Put `DELIMITER //` before every CREATE PROCEDURE, FUNCTION or TRIGGER.
- End it with `END //` and not `END;`.
- Always write `DELIMITER ;` afterwards.
- Leave a space after the word: write `DELIMITER ;`, not `DELIMITER;`.

If you forget `DELIMITER //`, you get `ERROR 1064 ... near '' at line 3`. MySQL stopped at the first `;` inside BEGIN.

---

## 3. Stored procedure: the basic shape

```sql
DROP PROCEDURE IF EXISTS setProjCost;   -- lets you run it again with no "already exists" error
DELIMITER //
CREATE PROCEDURE setProjCost()
BEGIN
	UPDATE Dept d
	SET proj_cost = (SELECT IFNULL(SUM(p.est_cost), 0)
	                 FROM Proj p
	                 WHERE p.dept_code = d.dept_code);
END //
DELIMITER ;

CALL setProjCost();       -- run it
SELECT * FROM Dept;       -- ALWAYS check that it worked
```

What it does, in plain words: "for each department, add up the est_cost of its projects and save it in proj_cost". A04 has no projects. SUM gives NULL there, so IFNULL turns it into 0.

Every procedure answer follows these steps:
1. Write `DROP ... IF EXISTS`.
2. Write `DELIMITER //`.
3. Write CREATE, then BEGIN ... END //.
4. Write `DELIMITER ;`.
5. Run it with CALL.
6. Run a SELECT to show the result.

---

## 4. Parameters: IN, OUT, INOUT

Think of a procedure as a vending machine:

- **IN**: what you put into the machine (money, the button you press). The procedure reads it.
- **OUT**: what comes out (the drink). The procedure fills it in.
- **INOUT**: you put something in, and a changed version comes back.

If you don't write anything, it means IN.

### IN example

```sql
CREATE PROCEDURE raiseSalary(IN dcode CHAR(3), IN pct DECIMAL(5,2))
BEGIN
	UPDATE Emp
	SET salary = salary + salary * pct / 100
	WHERE dept_code = dcode;
END //

CALL raiseSalary('A05', 10);   -- give A05 a 10% raise
```

Diya earned 80000. After the call she earns 88000.

### OUT example

```sql
CREATE PROCEDURE countEmp(IN dcode CHAR(3), OUT num INT)
BEGIN
	SELECT COUNT(*) INTO num FROM Emp WHERE dept_code = dcode;
END //

CALL countEmp('A01', @num);    -- an OUT needs a @variable to catch the answer
SELECT @num;                   -- shows 8
```

`CALL countEmp('A01', 5);` gives **ERROR 1414**. You can't put a value into an OUT parameter, only a `@variable`.

### INOUT example

```sql
CREATE PROCEDURE applyRaise(INOUT amount DECIMAL(10,2), IN pct DECIMAL(5,2))
BEGIN
	SET amount = amount + amount * pct / 100;
END //

SET @amt = 50000;
CALL applyRaise(@amt, 10);
SELECT @amt;                   -- 55000.00 (same variable, new value)
```

The number of values in CALL must match the number of parameters. If it doesn't, you get **ERROR 1318** (incorrect number of arguments).

---

## 5. Two kinds of variables

| | Local variable | User variable |
|---|---|---|
| Looks like | `tot_hrs` | `@tot_hrs` |
| Needs DECLARE? | Yes, at the top of BEGIN | No |
| Lives where | Only inside that BEGIN ... END | The whole time you're logged in |
| Picture | A note on a whiteboard, wiped when the procedure ends | A sticky note that stays until you log out |

```sql
BEGIN
	DECLARE tot_hrs INT;             -- local, must be declared first
	SET tot_hrs = 10;                -- fine
	SET @anything = 5;               -- fine, @ needs no DECLARE
	SET tot_hr = 3;                  -- typo -> ERROR 1193 Unknown system variable 'tot_hr'
END
```

ERROR 1193 nearly always means a spelling mistake in a variable name, or a variable you never DECLAREd.

---

## 6. Putting a query result into a variable

There are two ways, and both work:

```sql
-- Way 1: SET with brackets around the SELECT
SET tot_hrs = (SELECT SUM(proj_hours) FROM ProjAllocation WHERE emp_no = eno);

-- Way 2: SELECT ... INTO (good when you want 2 values at once)
SELECT COUNT(*), SUM(proj_hours) INTO numEmp, totHrs
FROM ProjAllocation WHERE proj_no = pno;
```

The SELECT must give back exactly one row. If it gives several rows, you get **ERROR 1172** (Result consisted of more than one row).

### Leading zeros trick

emp_no is text like '000029'. `MAX(emp_no) + 1` turns it into the number 30, so the zeros are lost.

```sql
SELECT LPAD(MAX(emp_no) + 1, 6, '0') INTO nextno FROM Emp;   -- '000030'
```

LPAD means "pad on the left with '0' until it is 6 characters long".

---

## 7. IF / ELSEIF / ELSE

```sql
IF tot_hrs = new_hrs THEN
	... same ...
ELSEIF tot_hrs < new_hrs THEN
	... increase ...
ELSE
	... decrease ...
END IF;
```

Common mistakes (all give 1064):
- writing `ELSE IF` (wrong) instead of `ELSEIF` (right)
- writing `ENDIF` instead of `END IF`
- forgetting the `;` after `END IF`
- forgetting `THEN`

### Example: chgTotHrs (from Prac07)

Employee 000012 works 2 + 6 + 10 = 18 hours over 3 projects. We want the new total to be 24.

- 18 < 24, so it's an increase ('INC').
- The difference is 24 − 18 = 6, shared over 3 projects, so 2 each.
- Every one of 000012's rows gets hrs_update = 2.00 and inc_dec = 'INC'.

Watch out: the Prac07 version had no `WHERE emp_no = eno` in the first UPDATE, so it changed every row in the table. Always check that each UPDATE has a WHERE.

---

## 8. Stopping with an error: SIGNAL

SIGNAL throws your own error message. MySQL stops, and nothing gets saved.

```sql
DECLARE err_msg VARCHAR(100);
...
IF (SELECT COUNT(*) FROM Emp WHERE emp_no = eno) = 0 THEN
	SET err_msg = CONCAT('Employee ', eno, ' does not exist');
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
END IF;
```

When you call it with a bad value, you see:
```
ERROR 1644 (45000): Employee 999999 does not exist
```

That means it worked. ERROR 1644 is your own message.

- `'45000'` is the code for "user-made error". Learn it by heart.
- `COUNT(*) = 0` is the easy way to ask "does this exist?".
- CONCAT puts the bad value into the message, which tests often ask for.

### Other way: LEAVE (exit quietly, no error)

```sql
CREATE PROCEDURE assignProjB(...)
proc_label: BEGIN                          -- give BEGIN a name
	IF (SELECT COUNT(*) FROM Emp WHERE emp_no = eno) = 0 THEN
		SELECT 'Employee does not exist' AS Message;
		LEAVE proc_label;                  -- jump out, skip the rest
	END IF;
	INSERT ...
END proc_label //
```

### Fix the value instead of stopping

```sql
IF hrs < 0 THEN
	SET hrs = NULL;        -- negative hours -> store NULL
END IF;
```

---

## 9. LOOP

A LOOP repeats forever until you LEAVE it.

```sql
CREATE PROCEDURE sumTo(IN n INT, OUT total INT)
BEGIN
	DECLARE i INT DEFAULT 1;
	SET total = 0;
	add_loop: LOOP                -- the label goes BEFORE LOOP, with a colon
		IF i > n THEN
			LEAVE add_loop;       -- the exit door
		END IF;
		SET total = total + i;
		SET i = i + 1;            -- forget this and it never ends
	END LOOP add_loop;
END //

CALL sumTo(3, @t);  SELECT @t;   -- 6
```

Walk-through for n = 3:

| i | i > 3? | total |
|---|---|---|
| 1 | no | 0 + 1 = 1 |
| 2 | no | 1 + 2 = 3 |
| 3 | no | 3 + 3 = 6 |
| 4 | yes, LEAVE | 6 |

If CALL never finishes, you made an infinite loop. Press **Ctrl+C**, and you get `ERROR 1317 Query execution was interrupted`. Use `>` rather than `=` in the exit test, so that a large starting value still leaves the loop.

---

## 10. Cursor (going through rows one at a time)

Picture a stack of paper timesheets: pick up the top sheet, read it, put it down, repeat until the pile is empty.

| Step | Code | Paper picture |
|---|---|---|
| Choose the pile | `DECLARE curEmp CURSOR FOR SELECT ...;` | Which sheets |
| What to do when empty | `DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;` | "When there are no more sheets, raise a flag" |
| Start | `OPEN curEmp;` | Put the pile on the desk |
| Take one | `FETCH curEmp INTO fullName;` | Pick up the top sheet |
| Stop? | `IF done = 1 THEN LEAVE ...` | Is the flag up? |
| Finish | `CLOSE curEmp;` | Put the pile away |

```sql
CREATE PROCEDURE deptEmpList(IN dcode CHAR(3), OUT eList VARCHAR(1000))
BEGIN
	DECLARE done INT DEFAULT 0;                    -- 1. variables
	DECLARE fullName VARCHAR(30);
	DECLARE curEmp CURSOR FOR                      -- 2. cursor
		SELECT CONCAT(first_name, ' ', last_name) FROM Emp WHERE dept_code = dcode;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;   -- 3. handler

	SET eList = '';
	OPEN curEmp;
	get_emp: LOOP
		FETCH curEmp INTO fullName;
		IF done = 1 THEN
			LEAVE get_emp;
		END IF;
		IF eList = '' THEN
			SET eList = fullName;                      -- first name: no comma
		ELSE
			SET eList = CONCAT(eList, ', ', fullName); -- later names: add a comma
		END IF;
	END LOOP get_emp;
	CLOSE curEmp;
END //

CALL deptEmpList('A03', @list);
SELECT @list;   -- Vincenzo Lucchesi, Adrian Souza, Apurva Banerjee, Ying Lee
```

The DECLARE order matters: variables first, then the cursor, then the handler. Get it wrong and you see **ERROR 1337 or 1338**.

Other cursor errors:
- FETCH into 1 variable when the SELECT has 2 columns gives **1328**.
- No NOT FOUND handler gives **1329** (No data).
- If eList starts as NULL instead of `''`, CONCAT gives NULL and the list comes out empty, with no error. Always `SET eList = '';` first.

---

## 11. Stored function

A function is like a procedure, but it gives back one value and you use it inside a SELECT.

```sql
DROP FUNCTION IF EXISTS empFullName;
DELIMITER //
CREATE FUNCTION empFullName(eno CHAR(6))
RETURNS VARCHAR(30)          -- what type comes back
READS SQL DATA               -- needed on this server, otherwise ERROR 1418
BEGIN
	DECLARE fname VARCHAR(30);
	SELECT CONCAT(first_name, ' ', last_name) INTO fname FROM Emp WHERE emp_no = eno;
	RETURN fname;            -- give the value back
END //
DELIMITER ;

SELECT proj_no, empFullName(leader) FROM Proj;   -- use it like CONCAT or SUM
```

| | Procedure | Function |
|---|---|---|
| Run with | `CALL p();` | inside `SELECT f();` |
| Gives back | 0 or more values via OUT | exactly one value via RETURN |
| Extra words | none | `RETURNS type` + `READS SQL DATA` or `DETERMINISTIC` |

---

## 12. Triggers

A trigger is a motion sensor on a table. When someone does an INSERT, UPDATE or DELETE on that table, your code runs automatically. You never CALL a trigger.

```sql
DROP TRIGGER IF EXISTS after_proj_insert;
DELIMITER //
CREATE TRIGGER after_proj_insert
	AFTER INSERT ON Proj        -- WHEN + WHAT + WHICH TABLE
	FOR EACH ROW                -- always write this
BEGIN
	UPDATE Dept
	SET proj_cost = IFNULL(proj_cost, 0) + IFNULL(NEW.est_cost, 0)
	WHERE dept_code = NEW.dept_code;
END //
DELIMITER ;
```

Test it: insert a project for A04 with est_cost 2500, then run `SELECT * FROM Dept;`. A04's proj_cost goes from 0 to 2500, and you never touched Dept yourself.

### NEW and OLD

NEW is the row after the change. OLD is the row before it.

| Event | OLD | NEW |
|---|---|---|
| INSERT | does not exist | the new row |
| UPDATE | the row before | the row after |
| DELETE | the deleted row | does not exist |

Using OLD in an INSERT trigger, or NEW in a DELETE trigger, gives **ERROR 1363**.

Example: `UPDATE Proj SET est_cost = 3000 WHERE proj_no = 'C03108';` where it was 2500.
OLD.est_cost = 2500 and NEW.est_cost = 3000. Dept needs: take away 2500, add 3000.

```sql
-- after UPDATE:
SET proj_cost = IFNULL(proj_cost,0) - IFNULL(OLD.est_cost,0) + IFNULL(NEW.est_cost,0)
-- after DELETE:
SET proj_cost = IFNULL(proj_cost,0) - IFNULL(OLD.est_cost,0)
```

### BEFORE or AFTER?

- **BEFORE**: check or change the row before it's saved. Use it to reject a value with SIGNAL, or fix it with `SET NEW.col = ...`. A security guard at the door.
- **AFTER**: the row is already saved, so update another table (totals, counts). An accountant updating the books afterwards.

`SET NEW.x = ...` inside an AFTER trigger gives **ERROR 1362**. Use BEFORE for that.

### Why IFNULL? (NULL "poisons" maths)

```
1000 + NULL = NULL     -- not 1000!
```

Dept.proj_cost starts as NULL for A01 to A04. Without IFNULL, adding a cost leaves it NULL. `IFNULL(x, 0)` means "if x is NULL, use 0".

Prac08 instead wrote out every case with IF/ELSEIF (old NULL? new NULL?). Both are correct. IFNULL is shorter.

### Trigger that rejects bad data (BEFORE + SIGNAL)

```sql
CREATE TRIGGER before_alloc_insert
	BEFORE INSERT ON ProjAllocation
	FOR EACH ROW
BEGIN
	DECLARE err_msg VARCHAR(100);
	IF NEW.proj_hours < 0 OR NEW.proj_hours > 40 THEN
		SET err_msg = CONCAT('The hours, ', NEW.proj_hours, ', must be between 0 and 40');
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = err_msg;
	END IF;
END //
```

`INSERT ... VALUES ('000031','C03108',50);` gives `ERROR 1644 (45000): The hours, 50, must be between 0 and 40`, and the row is not inserted.

One trigger covers one event. To check both INSERT and UPDATE, you need two triggers (same body, different names).

### Trigger that quietly fixes the data (a "clamp")

```sql
CREATE TRIGGER before_proj_insert
	BEFORE INSERT ON Proj
	FOR EACH ROW
BEGIN
	IF NEW.initial_cost > NEW.est_cost THEN
		SET NEW.initial_cost = NEW.est_cost;   -- cut it down to the max
	END IF;
END //
```

Insert initial_cost 5000 with est_cost 900, and 900 is saved. No error. On UPDATE you can use `SET NEW.initial_cost = OLD.initial_cost;`, which means "ignore the bad change, keep the old value".

### The one thing a trigger can't do (ERROR 1442)

A trigger on Proj cannot change Proj. It also can't start a chain that comes back and changes Proj:

```
INSERT Proj -> trigger inserts ProjAllocation -> trigger on ProjAllocation updates Proj
ERROR 1442: Can't update table 'Proj' in stored function/trigger because it is already used...
```

To change the same row, use a BEFORE trigger with `SET NEW.col = ...`.

### Good to know

- `ON DELETE CASCADE` deletes child rows, but it does not fire the triggers on the child table.
- You can't CREATE OR REPLACE a trigger. Write `DROP TRIGGER IF EXISTS` first, otherwise you get **1359 already exists**.
- To see your triggers: `SHOW TRIGGERS;`

---

## 13. Adding columns, then filling them (ALTER + UPDATE JOIN)

```sql
ALTER TABLE Proj
	ADD COLUMN emp_cnt INT NULL,
	ADD COLUMN tot_hours INT NULL;

UPDATE Proj SET emp_cnt = 0, tot_hours = 0;     -- start at 0 (C03107 has nobody)

UPDATE Proj p
INNER JOIN (SELECT proj_no, COUNT(*) AS cnt, IFNULL(SUM(proj_hours),0) AS hrs
            FROM ProjAllocation
            GROUP BY proj_no) pa
	ON p.proj_no = pa.proj_no
SET p.emp_cnt = pa.cnt, p.tot_hours = pa.hrs;
```

Picture it like this:
1. The inner SELECT makes a small summary table, one row per project (C03100: 3 people, 22 hours, and so on).
2. The JOIN matches each Proj row to its summary row.
3. SET copies the numbers across.

After that, triggers on ProjAllocation keep the numbers right:
- insert: count + 1, hours + NEW
- update: hours − OLD + NEW
- delete: count − 1, hours − OLD

Running the ALTER a second time gives **ERROR 1060 Duplicate column name**. The column is already there, so just carry on.

---

## 14. Views

A view is a saved SELECT. It stores no data of its own. Every time you look at it, it runs the SELECT again on the real tables. Think of a window: if the room changes, what you see through the window changes too.

```sql
DROP VIEW IF EXISTS ProjDetails;
CREATE VIEW ProjDetails AS
	SELECT p.proj_no, p.proj_name, d.dept_name,
	       CONCAT(e.first_name, ' ', e.last_name) AS leader_name, p.est_cost
	FROM Proj p
	INNER JOIN Dept d ON p.dept_code = d.dept_code
	INNER JOIN Emp  e ON p.leader = e.emp_no;

SELECT * FROM ProjDetails;
```

- **View on a view**: `CREATE VIEW BigProjects AS SELECT ... FROM ProjDetails WHERE est_cost >= 5000;`
- **It is live**: run `UPDATE Proj SET est_cost = 6000 WHERE proj_no='C03104';`, and C03104 now shows up in BigProjects.
- **Change a view**: `CREATE OR REPLACE VIEW name AS ...`
- **Give a calculated column a name** with `AS leader_name`, otherwise its column name is the whole CONCAT(...) expression.

### Can you UPDATE through a view?

- **Yes**: for a simple view on one table. The change goes into the real table.
- **No**: if the view has GROUP BY, COUNT, SUM, DISTINCT and so on. You get **ERROR 1288 not updatable**. That makes sense: there's no single real row behind "total_hours".

### WITH CHECK OPTION

```sql
CREATE VIEW SalesEmp AS
	SELECT emp_no, first_name, last_name, dept_code, salary
	FROM Emp WHERE dept_code = 'A01'
	WITH CHECK OPTION;
```

`UPDATE SalesEmp SET dept_code = 'A02' ...` gives **ERROR 1369 CHECK OPTION failed**. The view won't let you push a row out of itself.

To see your views: `SHOW FULL TABLES WHERE Table_type = 'VIEW';`

---

## 15. Indexes

Without an index, MySQL reads every row to find 'Smith', like reading a whole book to find one word. An index is the book's index at the back: look up the word, jump to the page.

```sql
CREATE INDEX idx_emp_lastname ON Emp(last_name);
SHOW INDEX FROM Emp;
EXPLAIN SELECT * FROM Emp WHERE last_name = 'Smith';
DROP INDEX idx_emp_lastname ON Emp;
```

How to read EXPLAIN:
- The **key** column shows idx_emp_lastname when the index is used. NULL means it isn't used.
- The **rows** column is how many rows MySQL thinks it must read. Smaller is better.
- The **type** column: ALL means it reads the whole table (slow). ref or const means it uses an index (fast).

The primary key already has an index, called PRIMARY. Indexes make SELECT faster but INSERT/UPDATE a little slower, because the index has to be updated too.

---

## 16. How to read a MySQL error

```
ERROR 1064 (42000) at line 12: You have an error in your SQL syntax; ... near 'END IF' at line 9
      ^^^^                                                                  ^^^^^^^^^^^^^^^^^^^^^^^^
      the number (look it up)                                               where MySQL got confused
```

1. **Read the number** and look it up in the cheat sheet at the end of PracTest4_Prediction.sql.
2. **For 1064, look at the word after "near", then look just before it.** The mistake is almost always on the line before the "near" text.
   - `near 'END IF'` usually means a missing `;` on the line above, or a missing THEN.
   - `near ''` (empty) usually means you forgot `DELIMITER //`.
3. **Run `SHOW WARNINGS;`** when something "worked" but looks wrong.
4. **Watch the prompt:**
   - `->` means MySQL is waiting for more. You forgot `;` or `//`. Type it and press Enter.
   - `'>` or `">` means you have an unclosed quote. Type `'` then `;`.
5. **"Already exists" (1304, 1359, 1050)**: run `DROP ... IF EXISTS name;` and create it again.
6. **The procedure was created, but CALL gives a wrong result**: SELECT the tables to check the data. Then look for a missing WHERE, a NULL in your maths (use IFNULL), or the wrong variable name.

### The 10 errors you will most likely see

| Code | Meaning | Fix |
|---|---|---|
| 1064 | Syntax error | Look just before "near", or add DELIMITER // |
| 1046 | No database selected | `USE dswork;` |
| 1146 | Table doesn't exist | Check the spelling/case, and SOURCE the files first |
| 1054 | Unknown column | Spelling, wrong alias, or NEW/OLD on the wrong table |
| 1193 | Unknown system variable | Variable typo, or you didn't DECLARE it |
| 1304 / 1359 | Procedure / trigger already exists | DROP ... IF EXISTS first |
| 1305 | Procedure does not exist | Name typo |
| 1418 | Function needs DETERMINISTIC... | Add `READS SQL DATA` |
| 1442 | Trigger can't update its own table | Use BEFORE + `SET NEW.col` |
| 1644 | Your SIGNAL message | Not a bug, your check worked |

---

## 17. Test-day checklist

- [ ] `USE dswork;` first.
- [ ] Before you SOURCE the tables file, drop the child tables first: `DROP TABLE IF EXISTS ProjAllocation, Proj, Emp, Dept;`
- [ ] Every CREATE PROCEDURE, FUNCTION or TRIGGER has `DROP ... IF EXISTS`, then `DELIMITER //`, then `END //`, then `DELIMITER ;`.
- [ ] Put DECLAREs at the top: variables, then cursor, then handler.
- [ ] Every UPDATE has a WHERE. Read it twice.
- [ ] Use IFNULL wherever NULL could appear in maths.
- [ ] Every CALL, INSERT, UPDATE or DELETE is followed by a SELECT that shows the result.
- [ ] Copy each test's error message into your file as a comment. It shows the marker that your check works.
- [ ] Functions have `READS SQL DATA`.
- [ ] Watch the prompt: `->` means unfinished. Finish with `;` or `//`.
