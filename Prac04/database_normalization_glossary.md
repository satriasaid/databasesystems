# Glossary: ER Mapping & Normalization (ISYS5008 Lecture 4)

## Keys

**Primary key (PK)** — The attribute (or group of attributes) chosen to uniquely identify each row.
Example: `Student(studentID, firstName, lastName)` — `studentID` is the PK.

**Composite key** — A primary key made of two or more attributes together, because no single one is unique alone.
Example: `Enrolment(studentID, courseID, grade)` — the pair `{studentID, courseID}` together is unique, so it's the composite key.

**Foreign key (FK)** — An attribute in one table that is the primary key of another table, used to link the two tables.
Example: `courseName` in `Student` referencing `Course(courseName)`.

**Superkey** — Any set of attributes that uniquely identifies a row, possibly with extra unnecessary attributes included.
Example: in `R(A,B,C,D)` with `{A,B}` unique, then `{A,B}`, `{A,B,C}`, `{A,B,C,D}` are all superkeys.

**Key** — A superkey with no extra baggage: removing any attribute breaks uniqueness.
Example: `{A,B}` is a key; `{A,B,C}` is not (C is unnecessary).

**Candidate key** — Any key that could be chosen as the primary key. A table may have several.
Example: in `R(X,Y,Z)`, if X and Y are each independently unique, `{X}` and `{Y}` are both candidate keys.

**Prime attribute** — Any attribute that is part of at least one candidate key.

**Non-prime (non-key) attribute** — Any attribute that is NOT part of any candidate key.

## Functional Dependencies (FDs)

**Functional dependency (X → Y)** — "Knowing X tells you exactly one value of Y."
Example: `studentID → studentName`.

**Trivial FD** — An FD that's automatically true (right side is a subset of left side), e.g. `{studentID, courseID} → studentID`.

**Full functional dependency** — Y depends on the WHOLE combination X, not just part of it.

**Partial functional dependency** — Y depends on only PART of a composite key.
Example: `{studentID, courseID} → studentName`, but really only `studentID → studentName`.

**Transitive dependency** — Y depends on X only indirectly through a middleman Z: X → Z → Y.
Example: `studentID → facId → facName`.

**Attribute closure (X+)** — All attributes reachable from X via known FDs. If X+ = all attributes, X is a key.

## Normal Forms

| Normal form | Rule | Typical fix |
|---|---|---|
| 1NF | Every cell has one indivisible value | Split multi-valued cells into separate rows |
| 2NF | 1NF + no non-prime attribute partially depends on a composite key | Move partially-dependent attributes to their own table |
| 3NF | 2NF + no non-prime attribute transitively depends on a key | Split off the middleman attribute into its own table |
| BCNF | Every determinant (left side of any FD) is a superkey | Decompose further |

## Anomalies (why normalize?)

- **Insertion anomaly**: can't add new data (e.g. a department) without unrelated data (e.g. an employee) already existing.
- **Deletion anomaly**: deleting one row accidentally erases other information (e.g. losing all record of a department when its last employee is deleted).
- **Update anomaly**: a single real-world fact (e.g. department location) must be updated in many rows, risking inconsistency.

Source: DS_2025S2_L04_ERMapping_Normalization.pdf
