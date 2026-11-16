# Stored Procedures in MySQL — Explained Simply

This note walks through the lecture slide by slide, using plain language and everyday examples. No prior database programming knowledge needed.

Think of a **database** as a giant filing cabinet, and **SQL** as the language you use to ask the cabinet questions ("give me all files about John") or update it ("change John's file"). A **stored procedure** is like a laminated instruction card you leave taped to the cabinet, so instead of explaining the same multi-step task every time, you just say "do card #7."

---

## Slide 1–2: Title and Copyright

Just the cover page for the lecture ("Introduction to Database Programming: Stored Procedures in MySQL") and a copyright notice. No technical content here.

## Slide 3: Learning Outcomes

This lists what you should be able to do by the end: understand why procedures matter, write a basic procedure, use procedures with inputs/outputs, and use logic (if/else, loops) and "cursors" (a way to go row-by-row through data) inside procedures. Think of it as the table of contents for the whole topic.

## Slide 4: Procedures and Functions in Databases

SQL by itself is mainly for defining data, querying it, and changing it — it isn't built like a general programming language (no loops or if/else built in). But databases add extra "programmable" objects — **stored procedures, functions, triggers, views** — that let you write reusable logic that lives inside the database server itself, not in your application code.

**Simple example:** Imagine SQL is like a basic calculator (add, subtract, look up numbers). A stored procedure is like adding a custom button to that calculator that runs a whole sequence of steps when pressed.

## Slide 5: Stored Procedure vs Stored Function

Two related but different objects:

- **Stored procedure**: created with `CREATE PROCEDURE`, run with `CALL`. It doesn't hand back a single value directly, but it can change its inputs or return a table of results.
- **Stored function**: created with `CREATE FUNCTION`, used inside an expression just like a built-in function (e.g., like `SUM()` or `NOW()`), and it always returns exactly one value.

**Simple example:** A stored function is like asking "what's 10% of $200?" and getting back one number ($20). A stored procedure is more like asking "process this whole order" — it might update several things and not just spit out one number.

## Slide 6: Why Stored Procedures and Functions?

Once you save a set of SQL instructions as a stored routine, apps don't need to repeat the same long SQL every time — they just call the routine by name. This is especially useful when:

- Multiple apps (written in different programming languages, e.g., Python, Java, mobile apps) all need to do the same database task.
- Security matters a lot.

**Concrete example:** A bank might have a stored procedure called `transferMoney`. Every app (website, ATM, mobile app) just calls `transferMoney` instead of writing its own raw SQL. Customers and apps never touch the raw account tables directly — they can only run approved procedures, which reduces the risk of mistakes or fraud, and every transfer gets logged consistently.

## Slide 7: Advantages and Trade-offs

- **Less network traffic**: Since the logic runs on the server, the app only sends "call this procedure" instead of a long chain of commands, so less data travels back and forth.
- **Trade-off**: The database server does more work, so it needs to be powerful enough to handle it.
- Lets you build a reusable "library" of business logic right inside the database (like an API).
- Helps control who's allowed to do what (permissions) and reduces security risks.

**Simple analogy:** Instead of mailing a recipe back and forth every time you want a cake baked, you leave the recipe at the bakery. You just call and say "bake cake #3" — faster and safer, but the bakery (server) does more of the work.

## Slide 8–9: Defining Stored Procedures and Functions (Syntax)

This shows the basic template:

```
CREATE PROCEDURE proc_name (parameter_list)
[COMMENT 'description']
statement;
```

```
CREATE FUNCTION proc_name (parameter_list)
RETURNS type
[COMMENT 'description']
statement;
```

Key parts explained simply:

- **proc_name**: just a sensible name you choose, like `resetBonus`.
- **parameter_list**: the "inputs" you feed into it (can be empty).
- **RETURNS**: only functions have this — it says what type of single value comes back (e.g., a number).
- **COMMENT**: an optional note describing what it does — good practice, like a sticky note explaining the recipe.
- **statement**: the actual instructions to run.

## Slide 10: Example Table — the Emp (Employee) Table

The lecture uses a sample employee table with columns like `empno` (employee ID), `firstname`, `lastname`, `salary`, `bonus`, `workdept` (department), etc. This table is the "filing cabinet" that all the upcoming examples will work with.

**Everyday picture:** Imagine an Excel spreadsheet listing employees, their department, salary, and bonus columns — that's the `Emp` table.

## Slide 11: Example 1 — Procedure Without Parameters

Scenario: at the start of every year, all employee bonuses need to be reset to zero.

```sql
CREATE PROCEDURE resetEmpBonus()
COMMENT 'Sets bonus field to zero for all employees in the Emp table.'
UPDATE Emp SET bonus = 0;
```

You run it by typing `CALL resetEmpBonus();`. This procedure has no inputs (empty parentheses `()`), so it does the exact same thing every time it's called.

**Concrete example:** It's like a "Reset" button on a remote control — pressing it always sets things back to the same default state, no questions asked. The benefit: if the company later decides everyone should get at least $200 bonus instead of $0, you only update this one procedure — every app that calls `resetEmpBonus()` automatically gets the new behavior without changing their own code.

## Slide 12–13: Parameters — IN, OUT, IN OUT

Parameters let you pass information into (or out of) a procedure, similar to filling in blanks on a form. Three types (or "modes"):

- **IN**: procedure reads/uses the value but can't change what the caller sees. (This is the default if you don't specify a mode.)
- **OUT**: procedure ignores the incoming value (it starts as blank/NULL) but sets a value that gets handed back to the caller.
- **IN OUT**: does both — reads an incoming value and can send back a changed one.

**Simple analogy:** Think of a drive-through order form.

- **IN** is like writing your order on the form — the kitchen reads it but you can't change what they wrote back.
- **OUT** is like the receipt they hand back to you — blank until they fill it in with your total.
- **IN OUT** is like a loyalty card — you hand it over with your current points (input), and they hand it back updated with new points (output).

## Slide 14: Example 2 — Procedure with an IN Parameter

Now the bonus reset amount isn't fixed at zero — management decides the number, and it may change each year.

```sql
CREATE PROCEDURE resetEmpBonus2(IN val DECIMAL(8,2))
COMMENT 'Sets bonus field to a value provided by management.'
UPDATE Emp SET bonus = val;
```

Call it with: `CALL resetEmpBonus2(100);` — this sets everyone's bonus to $100.

**Concrete example:** It's like a vending machine where you choose the price tier instead of it always charging the same amount — you plug in a number, and the machine reacts to what you gave it.

## Slide 15–16: Example 3 — Procedure for Inserting New Employees

When hiring someone, instead of making a staff member manually type a raw `INSERT` SQL command (risky and error-prone), you wrap it in a procedure. A form/window in the software collects the details, and behind the scenes it calls the procedure.

```sql
CREATE PROCEDURE insNewEmp(
  eno CHAR(6), fname VARCHAR(12), minit CHAR(1),
  lname VARCHAR(15), wdept CHAR(3)
)
COMMENT 'Insert new employee into table Emp.'
INSERT INTO Emp(empno, firstname, midinit, lastname, workdept, bonus)
VALUES(eno, fname, minit, lname, wdept, 0);
```

Called like: `CALL insNewEmp('100001', 'Lin', 'M', 'Soon', 'B01');`. Notice bonus is automatically set to 0 (new hires haven't earned one yet), and any other columns not listed become blank (`NULL`).

**Concrete example:** This is exactly like an online sign-up form — you fill boxes for name and department, hit submit, and the "insert new employee" logic runs automatically without you (or an HR staff member) ever writing SQL by hand.

## Slide 17–19: Compound Statements (Multiple Steps) and DELIMITER

So far, each procedure only ran one instruction. To run **several** steps in sequence, wrap them in a `BEGIN ... END` block — this is called a compound statement.

Problem: SQL treats a semicolon (`;`) as "end of command," which would cut off the procedure definition early if you have multiple semicolons inside it. Fix: temporarily change the "end of command" symbol to something else (like `//` or `$$`) using `DELIMITER`, write the whole procedure, then switch the delimiter back to `;`.

```sql
DELIMITER //
CREATE PROCEDURE resetEmpBonus()
COMMENT 'Sets bonus to 100 for dept A00, 50 for everyone else.'
BEGIN
  UPDATE Emp SET bonus = 100 WHERE workdep = 'A00';
  UPDATE Emp SET bonus = 50 WHERE workdep <> 'A00';
END
//
DELIMITER ;
```

**Simple analogy:** Imagine writing a recipe with multiple steps ("crack the eggs. mix the flour. bake at 180°C.") — each step ends with a period. But if your recipe card format uses a period to mean "end of card," you'd need to temporarily use commas instead so the whole recipe doesn't get cut off after step one. That's what `DELIMITER` does for a moment.

## Slide 20–22: Variables (Local and User-Defined)

Two kinds of variables can be used inside procedures:

- **Local variables**: declared with `DECLARE name TYPE [DEFAULT value]`. These only exist inside the specific block they're declared in — like a sticky note you throw away once the current task is done.
- **User-defined variables**: declared with `SET @name = value` (always start with `@`). These persist for your whole session (until you disconnect), so they can carry a value out of a procedure to be used afterward.

**Concrete example:** A local variable is like scratch paper you use to do maths mid-task then discard. A user-defined variable (`@result`) is like writing the final answer on a whiteboard that stays up so anyone in the room (any command in your session) can look at it afterward.

## Slide 23: Example 6 — Local Variables in Action

This procedure automatically generates a new employee ID by finding the current highest ID and adding 1, then inserts the new employee with that generated ID.

```sql
DECLARE nextid CHAR(6);
SELECT MAX(empno)+1 FROM Emp INTO nextid;
INSERT INTO Emp(empno, firstname, midinit, lastname, workdept)
VALUES (nextid, fname, minit, lname, wdept);
```

**Concrete example:** Like a "Take a Number" ticket dispenser at a deli counter — it looks at the last number given out, adds 1, and hands you the next one automatically, so no two customers get the same number.

## Slide 24: Example 5 — Setting Multiple Variables at Once

```sql
SET @t1=1, @t2=2, @t3=4;
SELECT @t1, @t2, @t3, @t4:= @t1+@t2+@t3;
```

This sets three variables, then in the same query calculates a fourth (`@t4`) as their sum (1+2+4=7) using the `:=` assignment operator. This just shows the mechanics of assigning and combining variables — like doing basic maths with labeled boxes.

## Slide 25: Example 7 — Using an OUT Parameter

Goal: count how many employees work in a specific department, and get that count back out of the procedure.

```sql
CREATE PROCEDURE countNumEmp(IN dep CHAR(3), OUT ecount INT)
COMMENT 'Count the number of employees in a given department.'
SELECT COUNT(*) FROM Emp WHERE workdept = dep INTO ecount;
```

Call it: `CALL countNumEmp('A00', @result); SELECT @result;` — this tells you, say, that department A00 has 12 employees.

**Concrete example:** Like asking a librarian, "how many books are in the mystery section?" — you give them the input (the section name), and they hand you back one number.

## Slide 26–28: Flow Control — IF Statements

Just like everyday decision-making, procedures can branch based on conditions using `IF ... THEN ... ELSE ... END IF`, plus `ELSEIF` for extra conditions.

```sql
CREATE PROCEDURE setVal2(val INTEGER, OUT outVal INTEGER)
BEGIN
  SET outVal = val;
  IF val > 100 THEN
     SET outVal = 100;
  END IF;
END
```

**Concrete example:** This is a "cap" rule — like a store policy saying "if the discount calculates to more than 100%, just cap it at 100%." Feed in 200, and the procedure caps the output at 100.

## Slide 29–31: Loops (LOOP, LEAVE, ITERATE)

A `LOOP` repeats a block of statements until told to stop:

- `LEAVE` exits the loop (like `break` in other programming languages).
- `ITERATE` jumps back to the top of the loop to try again (like `continue`).

```sql
CREATE PROCEDURE doIterate(p1 INTEGER)
BEGIN
  label1: LOOP
    SET p1 = p1 + 1;
    IF p1 = 10 THEN
        LEAVE label1;
    END IF;
  END LOOP label1;
  SET @x = p1;
END
```

This keeps adding 1 to `p1` until it hits exactly 10, then stops. **Warning shown in the slide:** if you start with `p1 = 15`, it will never equal exactly 10 — the loop runs forever! This highlights a common real bug: infinite loops happen when your stopping condition can never actually be met.

**Concrete example:** Picture a treadmill set to stop "when the display reads 10 km." If you start the display already at 15 km and it only counts up, it will never show exactly 10 again — so it never stops. That's exactly the trap in this example.

## Slide 32–34: Cursors — Moving Through Rows One at a Time

A **cursor** is a pointer that lets you walk through a set of query results one row at a time, similar to using your finger to read down a list line by line. Four steps to use one:

1. **DECLARE** the cursor (define which query's results it will point to).
2. **OPEN** it (start pointing at the results).
3. **FETCH** each row into variables, one at a time.
4. **CLOSE** it when done.

Since a loop fetching rows eventually runs out of rows, you also set up a **handler** that detects "no more rows" (`NOT FOUND`) and flips a flag to `TRUE`, so your loop knows when to stop.

**Concrete example:** Imagine going through a stack of physical timesheets one by one to add up hours: you pick up (fetch) the top sheet, read it, set it aside, and repeat — until there's no more sheets left (the "NOT FOUND" moment), at which point you stop.

## Slide 35: Example 11 — Full Cursor Example

This procedure goes through every employee whose job is "Programmer," and builds a comma-separated list of their full names.

```sql
DECLARE curProgNames CURSOR FOR
  SELECT CONCAT(firstname, ' ', lastname) FROM Emp WHERE job = 'Programmer';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
OPEN curProgNames;
getProgNames: LOOP
  FETCH curProgNames INTO fullName;
  IF done = 1 THEN LEAVE getProgNames; END IF;
  SET pList = CONCAT(pList, ', ', fullName);
END LOOP getProgNames;
CLOSE curProgNames;
```

**Concrete example:** Like flipping through a class roster and calling out only the names of students enrolled in "Programming," writing each one down on a running list until you reach the end of the roster.

## Slide 36: Exercise

A practice task asking students to modify Example 11 so that, instead of just building a text list, it actually inserts each programmer's name into a new table called `Programmers`. This is meant to be done as self-practice, not something the slide answers directly.

## Slide 37: Example 12 — Two Cursors at Once

A more advanced example uses **two cursors simultaneously**, fetching a row from each of two tables (`t1` and `t2`) at the same time, comparing values, and inserting the smaller one into a third table `t3`.

**Concrete example:** Like comparing two people's height charts row by row — for each pair, you record whichever is shorter into a new results sheet — continuing until either chart runs out of rows.

## Slide 38: References

A list of official MySQL documentation links for further reading on stored procedures, compound statements, flow control, and cursors — useful if you want to dig deeper after the basics.

## Slide 39: Summary

Recaps the whole lecture: stored procedures/functions/triggers add programming power to databases; they reduce network traffic, improve security, and control access; procedures can take IN/OUT/IN OUT parameters (IN is default); multiple steps require `BEGIN...END` and a temporary `DELIMITER`; variables can be local (temporary) or user-defined (persist for the session); `IF` and `LOOP` add decision-making and repetition; cursors let you process query results row by row.

## Slide 40: Closing/Logistics

Wraps up with "Happy Database Systems!" and course logistics: this week's practical covers subqueries and referential integrity, next week's lecture covers Triggers and Views, and the following practical will focus on stored procedures with Practical Test 3 coming up in the following week's lab.

---

### The Big Picture in One Sentence

A stored procedure is a saved, reusable set of database instructions — like a labeled macro button — that can take inputs, make decisions, loop through data, and hand back results, all without the application needing to repeat the same SQL every time.
