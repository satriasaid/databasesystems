# Database Systems – Lecture 8: Triggers, Views & Indexes (Explained Simply)

This note walks through the lecture slide by slide in plain language, with everyday examples. Think of a database as a big set of spreadsheets (called **tables**) that a program manages for you.

---

## Slide 1–3: Title & Learning Outcomes

This lecture covers three tools that make databases smarter and faster:

- **Triggers** – code that runs automatically when something happens to a table (like a smoke alarm that goes off when it detects smoke).
- **Views** – a "saved search" that looks like a table but is really just a stored question you can reuse.
- **Indexes** – a shortcut system that helps the database find data fast, like the index at the back of a textbook.

By the end, you should be able to write basic versions of all three in MySQL.

---

## Slide 4–7: What Are Triggers and Why Do We Need Them?

**The problem:** When you add, change, or delete data, you sometimes need extra checks or automatic actions. Simple rules (like "marks must be 100 or less") can be built into a table, but they can't do complex things like "update another table automatically."

**The solution — a trigger:** A trigger is a small piece of code attached to a table that wakes up automatically whenever something specific happens to that table (an insert, update, or delete).

**Simple example:** Imagine a library system. Every time a book is marked "returned" (an UPDATE), a trigger could automatically increase the "copies available" count on the shelf record — no human has to remember to do it manually.

Triggers are also called **ECA rules** (Event-Condition-Action):
- **Event** – something happens, e.g., "a new row is inserted."
- **Condition** – a yes/no check, e.g., "is the salary more than $0?"
- **Action** – what to do if the condition is true, e.g., "update another table."

---

## Slide 8–9: The Basic Structure of a Trigger

A trigger is created with a template that answers three questions:

1. **When?** – Before or after the event (`BEFORE` or `AFTER`).
2. **What event?** – Insert, update, or delete (`INSERT`, `UPDATE`, `DELETE`).
3. **What table?** – Which table it watches.

**"FOR EACH ROW"** means the trigger fires separately for every single row affected. If you insert 5 rows at once, a row-level trigger runs 5 times — once per row. (MySQL only supports this row-by-row style, not a "run once for the whole batch" style.)

*Analogy:* Imagine a bouncer checking IDs one person at a time as they enter a club, rather than checking the whole group's IDs together.

---

## Slide 10–13: The Building Blocks of a Trigger

- **Trigger time (`BEFORE`/`AFTER`)** – Do you want to react before the change actually happens (e.g., to block bad data) or after it happens (e.g., to update something else)?
- **Trigger event (`INSERT`/`UPDATE`/`DELETE`)** – Which action wakes the trigger up.
- **Trigger order** – If a table has multiple triggers for the same event, you can control which one runs first using `FOLLOWS` or `PRECEDES`.
- **Trigger body** – The actual instructions to run. If you need more than one instruction, wrap them in `BEGIN ... END`.

**Example:** You could have two "BEFORE INSERT" triggers on an `Emp` (employee) table — one to check the salary isn't negative, and another to log the insert time. The order clause decides which check happens first.

---

## Slide 14–15: Trigger Example 1 – Adding Up Salaries

**Goal:** Every time someone inserts a new salary into the `Emp` table, automatically add it to a running total.

```sql
CREATE TRIGGER before_emp_insert_total
BEFORE INSERT ON Emp
FOR EACH ROW
  SET @total = @total + NEW.salary;
```

**What happens:** If you insert an employee with salary 2400, then another with salary 1000, the variable `@total` automatically becomes 3400 — without you writing any extra addition code.

*Everyday analogy:* Think of a cash register that automatically adds up your total bill as you scan each item, instead of you doing the math yourself at the end.

---

## Slide 16: The Magic Words `OLD` and `NEW`

Inside a trigger, you often need to refer to the row's data:

- `NEW.column_name` – the value **after** the change (used in INSERT and UPDATE triggers).
- `OLD.column_name` – the value **before** the change (used in DELETE and UPDATE triggers).

**Simple way to remember it:** `OLD` = what it used to be, `NEW` = what it's becoming. In a DELETE, there's no "new" version (the row is gone), so only `OLD` exists. In an INSERT, there's no "old" version (it didn't exist before), so only `NEW` exists.

---

## Slide 17–18: Trigger Example 2 – Keep Department Totals Updated

**Scenario:** You have an `Emp` (employee) table and a `Dept` (department) table that stores a running total of salaries per department.

**Goal:** When a new employee is hired (inserted), automatically add their salary to their department's total.

```sql
CREATE TRIGGER after_emp_insert_total2
AFTER INSERT ON Emp
FOR EACH ROW
BEGIN
  IF NEW.salary IS NOT NULL THEN
    UPDATE Dept
    SET total_sal = total_sal + NEW.salary
    WHERE dept_num = NEW.dept_num;
  END IF;
END;
```

*Analogy:* Like a shared team expense tracker that automatically updates the team's total spend the moment someone logs a new expense.

---

## Slide 19: Trigger Example 3 – Adjusting for Salary Changes

**Goal:** When an employee's salary is *updated* (raised or lowered), adjust the department's total by the *difference*, not the full new salary.

```sql
UPDATE Dept
SET total_sal = total_sal + (NEW.salary - OLD.salary)
WHERE dept_num = NEW.dept_num;
```

**Example:** If an employee's salary goes from $1000 to $1200, the department total only increases by $200 (the difference) — not by $1200 again.

---

## Slide 20: Trigger Example 4 – Cleaning Up After a Delete

**Goal:** When an employee is *deleted*, subtract their salary from the department's total, since only `OLD` values exist for deletes.

```sql
UPDATE Dept
SET total_sal = total_sal - OLD.salary
WHERE dept_num = OLD.dept_num;
```

*Analogy:* If someone leaves a shared subscription plan, the trigger automatically removes their share of the cost from the group total.

---

## Slide 21: The "Mutating Trigger" Trap

**The problem:** You cannot have a trigger on a table try to modify *the very same table* that just triggered it. This causes a "mutating table" error because the database gets confused about which version of the data is currently valid.

*Analogy:* Imagine trying to edit a document while it's still being saved — the system won't know which version is the "real" one, so it blocks you.

---

## Slide 22–24: Handling Errors Nicely

Sometimes a `BEFORE` trigger needs to **reject** bad data (like a negative salary) before it's inserted. Instead of a cryptic error, MySQL lets you use `SIGNAL SQLSTATE` to write a clear, human-readable error message.

**Example:** A bookstore doesn't want the price of a book to be *lowered* accidentally.

```sql
CREATE TRIGGER before_book_update
BEFORE UPDATE ON Book
FOR EACH ROW
BEGIN
  IF NEW.price < OLD.price THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'The new price cannot be lower than the old price';
  END IF;
END;
```

*Analogy:* Like a checkout system that stops a cashier from scanning a discount that makes an item's price go negative, and shows a clear warning instead of just crashing.

---

## Slide 25: Checking and Managing Triggers

- `SHOW TRIGGERS;` – see all the triggers currently defined.
- `DROP TRIGGER <name>;` – delete a trigger you no longer need.
- Note: unlike some other databases, MySQL doesn't let you simply "pause" (disable) a trigger — you have to drop it and recreate it if needed.

---

## Slide 26–29: What Is a View?

A **view** is like a saved, reusable search. It looks and behaves like a table, but it doesn't store its own copy of the data — it's really just a stored `SELECT` query that pulls live data from the real ("base") tables whenever you use it.

- **Virtual view** – nothing is physically stored; the query runs fresh each time. (This is what MySQL supports.)
- **Materialized view** – the results are actually saved to disk (MySQL does *not* support this).

*Analogy:* A view is like a custom playlist on a music app. The playlist doesn't contain actual copies of the songs — it just points to songs stored elsewhere and displays them in your chosen order whenever you open it.

```sql
CREATE VIEW view_name AS
SELECT ... ;
```

---

## Slide 30–33: View Examples

**Example — Local Students:** Suppose you often need to find Australian students and the courses they're enrolled in. Instead of rewriting the join query every time, save it as a view:

```sql
CREATE VIEW LocalStudents AS
SELECT student_id, first_name, Student.course_id AS course
FROM Student INNER JOIN Course
ON country = 'Australia' AND Student.course_id = Course.course_id;
```

Now you can just write:

```sql
SELECT * FROM LocalStudents WHERE course = 'C20';
```

...instead of retyping the whole join every time.

*Analogy:* It's like saving a complicated filter in your email inbox (e.g., "unread emails from my boss this week") as a single click, instead of manually re-typing the filter conditions every time you want to check it.

You can also rename the columns shown by the view, e.g., turning `student_id` into `s_id`, similar to renaming a column header in a spreadsheet.

---

## Slide 34: Why Use Views? (Three Big Reasons)

1. **Simplicity** – Hide a complicated multi-table query behind a simple, single "table-like" name.
2. **Security** – Give someone access to only *part* of the data. For instance, a view could show customer names and cities but hide their credit card numbers, so you grant access to the view instead of the full table.
3. **Consistency** – If a formula (like calculating tax or a discount) is used in many places, define it once as a view and reuse it everywhere, so everyone gets the same calculation.

---

## Slide 35–36: The Limits of Views

- You usually **can't freely insert, update, or delete** through a view — especially if the view involves joins, calculations (like `SUM`), `GROUP BY`, or `ORDER BY`. The database can't always figure out which underlying table row your change should apply to.
- **Performance cost:** Since a view is really just a query in disguise, using a view based on a complex query can be slow, because the database still has to run that complex query underneath every single time.

*Analogy:* A view is like a window display in a shop — you can look through it easily, but you can't always reach through the glass to rearrange the actual items on the shelf behind it.

---

## Slide 37–38: What Is an Index and Why Does It Matter?

**The problem:** Without help, a database has to check *every single row* in a table to answer a search — this is called a full table scan, and it gets painfully slow as tables grow to millions of rows.

**The solution — an index:** A special structure (technically a **B-tree**, a kind of balanced search tree) that lets the database jump straight to the matching rows instead of scanning everything.

*Analogy:* This is exactly like the index at the back of a textbook. Without it, you'd flip through every page looking for "photosynthesis." With the index, you look up the word alphabetically and jump straight to page 214.

Indexes help with:
- Finding rows matching a `WHERE` condition quickly.
- Speeding up table joins.
- Finding the minimum or maximum value in a column quickly.

---

## Slide 39–41: Creating and Using an Index

```sql
CREATE INDEX <name> ON <Table>(<column>);
```

**Example:** Say you want to quickly find hardcover books with "Dragon" on the jacket, whose title contains "Manual."

```sql
CREATE INDEX HardInd ON Hardcover(jacket);
CREATE INDEX BookInd ON Books(title);
```

The database can now use `BookInd` to instantly narrow down books with "Manual" in the title, then use `HardInd` to narrow further to jackets mentioning "Dragon" — without scanning the whole table twice.

*Tip mentioned in the slides:* You can put the word `EXPLAIN` before a `SELECT` query to see exactly which indexes MySQL plans to use — like getting a "GPS route preview" before your query actually runs.

---

## Slide 42–44: The Trade-Off of Indexes (Database Tuning)

Indexes aren't free:

- **Pro:** They make searches (`SELECT`) much faster.
- **Con:** Every time you insert, update, or delete a row, the index also has to be updated — so too many indexes can slow down writing data.

**Example given in the slides:** In a bookstore database, if 70% of activity is "look up softcover books" and only 10% is "look up hardcover books," you should index `Softcover` but *not* `Hardcover` — indexing the rarely-searched table would only add overhead without much benefit.

*Analogy:* Adding shortcuts (indexes) is great for the roads you drive on often, but paving a shortcut to a place you almost never visit just wastes time and money for no real benefit.

Because picking the "right" indexes by hand is hard, database systems sometimes offer **tuning advisors** — automated tools that test different index combinations against real query patterns and recommend the best set.

---

## Slide 45: Summary

- **Triggers** automatically react to `INSERT`, `UPDATE`, or `DELETE` events, running `BEFORE` or `AFTER` the action — but you must avoid "mutating table" errors.
- **Views** are virtual tables built from a stored query; they simplify complex queries and help control access to sensitive data.
- **Indexes** speed up searching by letting the database jump directly to relevant rows, at the cost of slightly slower writes.

---

## Slide 46–47: References & Class Notes

The lecture points to the official MySQL documentation pages for Triggers, Views, and Indexes for further reading, plus a note that this week's practical class includes Prac Test 3, and the following week is a tuition-free week before Lecture continues with "Connecting via a programming language."
