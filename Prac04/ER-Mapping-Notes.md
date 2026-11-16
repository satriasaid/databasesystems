# Beginner's Guide: Mapping ER Models to Relational Schema & Normalization

This note walks through the lecture slide by slide, explaining each idea in plain, simple language. Think of it as a friendly translation of the original slides [file:1].

---

## Slides 1–3: Introduction

**Slide 1 – Title slide.** This is Lecture 4 of a Database Systems course. The two big topics are: (1) turning an ER diagram into database tables, and (2) "normalization," a way of cleaning up those tables so they don't have problems [file:1].

**Slide 2 – Copyright notice.** A legal notice reminding students not to redistribute the material. No technical content here [file:1].

**Slide 3 – Learning outcomes.** By the end of this lecture you should be able to: turn an ER diagram into tables, build those tables in MySQL, describe what goes wrong in a badly designed table (called "anomalies"), understand "functional dependencies" (a rule about how data relates), understand different kinds of keys, and check/fix a table so it meets standards called 1NF, 2NF, 3NF, and BCNF [file:1].

---

## Slide 4: The Big Picture — From Real World to Database

Think of building a database as a pipeline with three stages:
1. **Conceptual design** – you study the real-world problem and draw an ER diagram (this was last week's topic).
2. **Logical design** – you convert that diagram into a "relational schema" (a set of table definitions). This is what today's lecture focuses on.
3. **Physical design** – you actually build the real database (e.g., in MySQL).

The middle stage is described as going from "informal" (just diagrams) to "formal" (actual table structures) [file:1].

---

## Slide 5: What Is "Mapping"?

An ER diagram has three ingredients: **entities** (things, like Student), **relationships** (how things connect, like "registers in"), and **attributes** (details about things, like name or phone number). "Mapping" simply means translating these ER diagram ingredients into actual database tables, following a set of standard rules, so the resulting tables don't have duplicate or messy data [file:1].

---

## Slides 6–19: Six Steps to Convert ER Diagrams into Tables

### Slide 6 – Step 1: Turn entities into tables
Every "entity" (like Student) becomes a table. Every attribute (first name, phone number) becomes a column. The unique identifier (like Student ID) is underlined and called the **Primary Key (PK)** — it's the column that uniquely identifies each row [file:1].

### Slide 7 – Why relationships matter (Foreign Keys)
If tables aren't properly connected, problems occur: e.g., if you change a student's name in one table, does it update everywhere else? If you delete a course, what happens to students enrolled in it? To keep tables linked correctly, we copy the key from one table into another — this copied key is called a **Foreign Key (FK)** [file:1].

### Slide 8 – Foreign keys and "referential integrity"
A Foreign Key must always point to something that actually exists in the other table (you can't reference a student who doesn't exist). This rule is called **referential integrity** — it's how databases prevent broken links [file:1].

### Slide 9 & 10 – Step 2: Mapping "1-to-many" relationships
Example: many students can register in one course (many students → one course). The rule: take the primary key of the "one" side (Course) and add it as a foreign key inside the "many" side table (Student). Slide 10 shows a worked example with Student and Course tables [file:1].

### Slide 11 – Example: A relationship pointing to itself
Sometimes an entity relates to itself, like "Employee manages Employee" (a manager is also an employee). Here, you just add a column like `manager_empID` inside the same Employee table [file:1].

### Slide 12 & 13 – Step 3: Mapping "many-to-many" relationships
Example: many customers can buy many books (Purchase relationship). Here, you create a **brand new table** just for the relationship (e.g., "Purchase"), which contains the primary keys from both sides as foreign keys, plus any extra details like cost or date [file:1].

### Slide 14 – Step 4: Mapping "one-to-one" relationships
Example: a Student writes one ProjectReport, and each report belongs to one student. You can usually merge this into either table. If both sides are optional, you might choose the side that's more likely to have data (in this case, Student) [file:1].

### Slide 15 – Step 5: "Weak entities"
A weak entity is something that can't exist without its "owner." Example: a Player only makes sense within a Team. The Player table must include the Team's key as a foreign key, and the primary key becomes a combination of both [file:1].

### Slide 16 & 17 – Step 6: Three-way relationships
Sometimes three entities connect at once, like Book–Customer–Author all linked through "Reads" (who read which book by which author). This becomes its own table containing the keys from all three entities [file:1].

### Slide 18 – Extra tip: "Is-a" relationships
This is for cases like "Hardcover is a type of Book." You create one table for the general type (Book) and a separate table for the specific type (Hardcover), linked by a shared key [file:1].

### Slide 19 – Extra tip: Multiple values in one field
Relational tables don't allow a single cell to hold multiple values (like two phone numbers in one box). You must either: split into multiple rows, add extra columns, or create a separate linked table [file:1].

---

## Slides 20–24: Practice and Implementation

**Slide 20 – Exercise.** A practice diagram (Building, Room, Student, Unit) for students to convert into tables themselves [file:1].

**Slide 21–23 – From tables to real database.** Once you have your table designs, you still need more details: data types (is it text or a number?), size limits, and business rules (e.g., "a class can't have more than 500 students"). This extra documentation is called a **data dictionary** [file:1].

**Slide 24 – Turning designs into real MySQL code.** Shows an actual example of `CREATE TABLE` statements — the real code you'd type into MySQL to build the Course and Student tables, including how to set up a foreign key constraint [file:1].

---

## Slide 25: Transition to Part 2 — Normalization

This marks the start of the second half of the lecture: checking whether your tables are well-designed, and fixing them if not [file:1].

---

## Slides 26–30: Why "Normalization" Matters

**Slide 26 – What is normalization?** Even if you follow the ER-to-table steps carefully, your tables might still have hidden problems. "Normalization" is the process of checking and fixing tables to remove duplicate data and prevent errors [file:1].

**Slide 27–28 – A messy example.** Imagine one big Employee table that also stores department info (name, location) directly. Sample data shows the department info ("Administration," "B101") repeated for every employee in that department — that's wasteful and risky [file:1].

**Slide 29 – Three types of "anomalies" (problems)**
- **Insertion anomaly:** You can't add a new department unless you also add an employee for it (since employee ID can't be empty).
- **Deletion anomaly:** If you delete the last employee in a department, you accidentally lose all information about that department too.
- **Update anomaly:** If a department moves location, you must update it in *every single row* for that department — easy to miss and cause inconsistent data [file:1].

**Slide 30 – The fix: split the table (with a system).** The solution is to break the big table into smaller ones, but you need a systematic method — random splitting can create new problems. This method relies on understanding "functional dependencies" [file:1].

---

## Slides 31–38: Functional Dependencies (the key math concept)

**Slide 31 – What is a "functional dependency"?** Simply put: if knowing attribute A always tells you exactly one value of attribute B, then B "depends on" A. Example: knowing a Student ID always tells you exactly one student name [file:1].

**Slide 32 – Example.** In a Student table, `studentID → studentName` means each student ID maps to exactly one name. But it doesn't work backwards — a name (like "John") could belong to multiple different student IDs [file:1].

**Slide 33 – Dependencies with combinations of columns.** Sometimes a value depends on *two* columns together, not just one. Example: `{studentID, courseID} → dateStarted` (you need to know both the student AND the course to know when they started) [file:1].

**Slide 34 – "Full" vs "partial" dependency.** This distinguishes between a value that depends on the *whole* combined key versus one that only needs *part* of it. Example: if `{A,B} → C`, but actually just `A → C` on its own, then C only "partially" depends on the key — this is a red flag we'll fix later [file:1].

**Slide 35 – Keys and "closure."** A **key** is a column (or group of columns) that can determine every other column in the table (its "closure" covers everything). This is the mathematical way of finding valid keys [file:1].

**Slide 36 – Key vocabulary cheat-sheet**
- **Superkey:** any set of columns that uniquely identifies a row (may include extra unnecessary columns).
- **Key:** a superkey with no extra unnecessary columns.
- **Candidate key:** any valid key option (there might be more than one).
- **Primary key:** the one candidate key you officially choose to use.
- **Prime attribute:** a column that's part of some candidate key.
- **Non-prime attribute:** a column that isn't part of any candidate key [file:1].

**Slide 37 – Rules for reasoning about dependencies (Armstrong's Axioms).** These are logical rules (reflexivity, augmentation, transitivity, etc.) mathematicians use to prove which dependencies exist. You don't need to memorize the formal names — just know they're tools for figuring out what determines what [file:1].

**Slide 38 – Worked example.** Given some starting dependencies (A→B, B→C, B→D), the slide shows step-by-step how to prove that A alone can determine every other column — making A the key [file:1].

---

## Slides 39–50: The Normal Forms (Quality Checks for Tables)

**Slide 39 – Overview.** There's a checklist of "normal forms" (1NF, 2NF, 3NF, BCNF) that get progressively stricter. You check them in order — first 1NF, then 2NF, and so on [file:1].

### 1NF — First Normal Form (Slides 40–41)
**Rule:** Every cell must hold just one single, simple value — no lists or multiple values crammed into one box.
**Example:** A "studentTel" column holding two phone numbers in one cell breaks 1NF. Fix: give each phone number its own row [file:1].

### 2NF — Second Normal Form (Slides 42–44)
**Rule:** Every non-key column must depend on the *entire* key, not just part of it (no "partial dependency"). This rule only matters when your key is made of multiple columns combined.
**Example fix:** If `{studentID, studentTel}` is the combined key, but studentName only depends on studentID (not on studentTel), you split it into two tables — one for phone numbers, one for the rest of the student info [file:1].

### 3NF — Third Normal Form (Slides 45–48)
**Rule:** No non-key column should depend on another non-key column (called a "transitive dependency") — every non-key column must depend directly on the key, not indirectly through something else.
**Example fix:** If `facName` (faculty name) only depends on `facId`, and `facId` depends on `studentID`, that's an indirect chain. Fix: split into a Student table and a separate Faculty table [file:1].

### BCNF — Boyce-Codd Normal Form (Slides 49–50)
**Rule:** A stricter version of 3NF. Every column that determines another column must itself be a full key (a "superkey"), not just any random column.
**Example fix:** If column E determines column B, but E by itself isn't a valid key, you split the table so E and B live in their own smaller table [file:1].

---

## Slides 51–55: Wrap-Up

**Slide 51/52 – Exercise.** Students are asked to check their own earlier answer (from Slide 20) against 1NF, 2NF, 3NF, and BCNF [file:1].

**Slide 52/53 – Recap of the pipeline.** Same diagram as Slide 4, reinforcing that today covered the "logical design" stage, which then gets implemented as real SQL code [file:1].

**Slide 53/54 – Summary.** Key takeaways: ER diagrams can be systematically converted into database tables; a well-designed schema avoids duplicate data and update/insert/delete problems ("anomalies"); functional dependencies help identify keys and check normal forms; and any properly structured relational table is automatically at least in 1NF [file:1].

**Slide 54/55 – Closing.** Wraps up with practical class info: this week continues ER modelling practice, and next week covers SQL joins and a normalization worksheet [file:1].

---

## Quick Recap Table

| Concept | Plain-English Meaning |
|---|---|
| Primary Key | The column that uniquely IDs each row |
| Foreign Key | A copied key linking to another table |
| Functional Dependency | "A tells you exactly what B is" |
| 1NF | No multiple values crammed in one cell |
| 2NF | No column depends on only *part* of a combined key |
| 3NF | No column depends on another non-key column indirectly |
| BCNF | Stricter 3NF — anything that determines a value must be a full key |
| Anomaly | A data problem (insert/update/delete) caused by bad table design |
