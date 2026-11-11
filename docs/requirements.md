# Phase 1 requirements

## Purpose

Students can check grades, estimate final grades, and calculate GPA. Professors
can enter grades and view results. Phase 1 uses PostgreSQL; Java/JDBC is Phase 2.

## Data

`K = (pid, cid, sectionnumber, term)` identifies one course section.

| Table | Attributes |
| --- | --- |
| Professor | `pid`, `name` |
| Course | `cid`, `coursenumber`, `unit` |
| Department | `did`, `name`, `manageby` |
| Student | `sid`, `name`, `dept`, `unitrequirement` |
| WorksIn | `pid`, `did` |
| Teach | `K`, `dept` |
| Assignment | `K`, `id`, `weight`, `duedate` |
| Enroll | `K`, `sid` |
| Assign | `K`, `id`, `sid`, `grade`, `turnindate` |

## Relationships

| Relationship | Cardinality and participation |
| --- | --- |
| WorksIn | Many-to-many. Professor: zero or more departments. Department: one or more professors, including its manager. |
| Manage | Department: exactly one manager. Professor: zero or more managed departments, with membership required. |
| Student's department | Student: exactly one department. Department: zero or more students. |
| Teach | Section: one professor and course. Professor/course: zero or more sections. |
| Section's department | Section: one department. Department: zero or more sections. Its professor must work there. |
| Section's assignments | Assignment: one section. Section: zero or more assignments. |
| Enroll | Students/sections: many-to-many, optional on both sides. |
| Assign | Students/assignments: many-to-many. Each result references one assignment and matching enrollment. Both parents can have zero or more results. |

## Rules

- Positive IDs/section numbers; nonblank names/terms; unique department names.
- Course units: 1–12. Individual unit requirements: 1–300.
- Weights: greater than 0 through 100. Grades: 0–100, including decimals.
- One enrollment per student/section and one result per student/assignment.
- `NULL` or missing results are ungraded. Zero counts as a grade. Dates can be unknown.
- Parent records cannot be deleted while referenced.
- A department's manager membership must exist at commit. Create both in one transaction.
- Weights must total 100 before finalization. Drafts are allowed. Phase 2 will
  lock the `teach` row and check totals during assignment edits/finalization.

## Operations and queries

Users can add, search, update, and delete records. Reports include:

1. Courses and assignments by student/term.
2. Current grade, what-if final grade, and scores needed to reach a target.
3. Assignment minimum, maximum, average, and grade distribution.
4. Enrolled students with no recorded grades.
5. GPA from completed courses.
6. Professor grade trends across courses and terms.
7. Late submissions.

For graded assignments, let `E = SUM(grade * weight / 100)` and `W = SUM(weight)`.
Current grade is `100 * E / W`, or unknown if `W=0`. With total weight 100,
the average needed for target `T` is `100 * (T - E) / (100 - W)`.
Above 100 is unreachable; at/below 0 is secured. With no remaining work,
show the final grade. What-if scores do not change records.

A final grade requires total weight 100 and every assignment graded. Round
`E` to two decimals before assigning GPA points: A=4 (90+), B=3 (80+), C=2
(70+), D=1 (60+), F=0. GPA is unit-weighted. All completed attempts count;
there are no plus/minus grades. No completed courses means no GPA.

## Assumptions

- Names/course numbers can repeat. Section keys include term; `dept` depends on that key.
- Use `sid` for students, assignment `id` in `assign`, and section `term` instead of `termEnrolled`.
- Assignment IDs serve as labels. Grades are percentages; maximum points are not stored.
- Data is fictional. Peer reports show aggregates. Phase 2 handles login/access.
