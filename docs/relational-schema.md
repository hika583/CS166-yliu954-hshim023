# Relational schema

`K = (pid, cid, sectionnumber, term)` is the section key. SQL names are lowercase.

## Tables and keys

| Relation | Primary key | Foreign keys |
| --- | --- | --- |
| `professor(pid, name)` | `pid` | None |
| `course(cid, coursenumber, unit)` | `cid` | None |
| `department(did, name, manageby)` | `did` | `(manageby, did) -> worksin(pid, did)` |
| `worksin(pid, did)` | `(pid, did)` | `pid -> professor(pid)`; `did -> department(did)` |
| `student(sid, name, dept, unitrequirement)` | `sid` | `dept -> department(did)` |
| `teach(K, dept)` | `K` | `cid -> course(cid)`; `(pid, dept) -> worksin(pid, did)` |
| `assignment(K, id, weight, duedate)` | `(K, id)` | `K -> teach(K)` |
| `enroll(K, sid)` | `(K, sid)` | `K -> teach(K)`; `sid -> student(sid)` |
| `assign(K, id, sid, grade, turnindate)` | `(K, id, sid)` | `(K, id) -> assignment(K, id)`; `(K, sid) -> enroll(K, sid)` |

Department `name` is the only additional candidate key. Other names and course
numbers can repeat.

Result foreign keys must match the assignment and enrollment in the same
section. Managers/professors need matching department membership. The manager
FK is `DEFERRABLE INITIALLY DEFERRED` to allow both rows to be inserted before
commit. Deletes do not cascade.

## Types and constraints

- IDs and section numbers: positive integers.
- Names and terms: nonblank text; department names are unique.
- Course units: integer 1–12. Individual unit requirements: integer 1–300.
- Weight: `NUMERIC(5,2)`, greater than 0 and at most 100.
- Grade: `NUMERIC(5,2)`, 0–100 when present.
- Dates: `DATE`. Only `duedate`, `grade`, and `turnindate` allow NULL.
- Primary keys are unique and NOT NULL. Foreign keys require matching parents.

## Functional dependencies

| Relation | Dependencies |
| --- | --- |
| `professor` | `pid -> name` |
| `course` | `cid -> coursenumber, unit` |
| `department` | `did -> name, manageby`; `name -> did, manageby` |
| `student` | `sid -> name, dept, unitrequirement` |
| `teach` | `K -> dept` |
| `assignment` | `(K, id) -> weight, duedate` |
| `assign` | `(K, id, sid) -> grade, turnindate` |
| `worksin`, `enroll` | All columns are in the primary key; no non-key attributes. |

`dept` does not determine `unitrequirement`. A section number alone is not a key.

## Normalization

The tables are in 3NF: non-key attributes depend on the whole key, with no
non-key-to-non-key dependencies. Every listed determinant is a candidate key,
so these dependencies also meet BCNF.

Names, units, and assignment details are stored once, avoiding repeated updates
across grades. Sections can be inserted before enrollments and assignments
before results. Deleting a result does not delete its assignment.

Final grades/GPA are calculated to avoid stale totals. The `enrollment_grades`
view calculates weights, earned points, current grades, and final grades.

## Rules handled by the application

- A `CHECK` cannot enforce weights totaling 100 across rows. Phase 2 will lock
  `teach` during assignment edits/finalization and check the total. The view
  returns finals only for fully graded, 100-weight schemes.
- What-if calculations must not overwrite recorded grades.
- Phase 2 handles access to individual grades and aggregate peer reports.
- Grade/GPA formulas and repeated-attempt rules are in [requirements.md](requirements.md).

## Changes from the draft

Use `sid` for students, add `id` to `assign`, and include `term` in section/dependent
keys. `dept` is non-key. Grades are decimal percentages; unit requirements are per student.
