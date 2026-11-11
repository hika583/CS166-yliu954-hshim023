# Relational schema and normalization

SQL identifiers are unquoted lowercase names. In the definitions below, `K`
means `(pid, cid, sectionnumber, term)`, the key of one section offering. Each
appearance of `K` expands to those four columns, not a separate stored column.

## Relations and keys

| Relation and attributes | Primary key | Foreign keys | Other candidate keys |
| --- | --- | --- | --- |
| `professor(pid, name)` | `pid` | None | None assumed |
| `course(cid, coursenumber, unit)` | `cid` | None | None assumed |
| `department(did, name, manageby)` | `did` | `(manageby, did)` references `worksin(pid, did)` | `name` |
| `worksin(pid, did)` | `(pid, did)` | `pid` references `professor`; `did` references `department` | None additional |
| `student(sid, name, dept, unitrequirement)` | `sid` | `dept` references `department(did)` | None assumed |
| `teach(K, dept)` | `K` | `cid` references `course`; `(pid, dept)` references `worksin(pid, did)` | None assumed |
| `assignment(K, id, weight, duedate)` | `(K, id)` | `K` references `teach` | None assumed |
| `enroll(K, sid)` | `(K, sid)` | `K` references `teach`; `sid` references `student` | None additional |
| `assign(K, id, sid, grade, turnindate)` | `(K, id, sid)` | `(K, id)` references `assignment`; `(K, sid)` references `enroll` | None additional |

The `worksin` composite references ensure the department manager and each
section's professor actually work in the relevant department. Together with
the `worksin` parent references, they also guarantee that the professor and
department exist. `assign` uses both composite foreign keys to prevent a result
from mixing an assignment and an enrollment from different offerings.

The department-manager foreign key is `DEFERRABLE INITIALLY DEFERRED` because
departments and their manager memberships refer to one another. Insert both
inside a transaction; PostgreSQL checks that relationship at commit. Other
foreign keys are checked normally. There are no cascading deletes; dependent
records must be handled explicitly before deleting their parents.

## Attributes and declarative constraints

All attributes are NOT NULL except `assignment.duedate`, `assign.grade`, and
`assign.turnindate`. Keys and other numeric identifiers use integers. Names and
terms use text. Weights and grades use `NUMERIC(5,2)`, and dates use `DATE`.

| Constraint | Meaning |
| --- | --- |
| Positive IDs and section numbers | Reject zero/negative identifiers. |
| Nonblank names and terms | Reject empty or whitespace-only text. Terms such as `2026-Fall` identify separate offerings. |
| `department.name` UNIQUE | Departments have distinct names in this dataset. |
| `course.unit` between 1 and 12 | Courses have positive, bounded unit values. |
| `student.unitrequirement` between 1 and 300 | The individual graduation unit requirement is positive and bounded. |
| `assignment.weight > 0 AND weight <= 100` | Each assignment contributes a valid positive percentage. |
| `assign.grade` between 0 and 100 when present | Zero is a real grade; NULL is an unrecorded grade. |

Names are not person identifiers. Course numbers are not assumed globally
unique, and section numbers can be reused in another offering. No uniqueness
constraint is added for these attributes.

## Functional dependencies

The following are the relevant nontrivial functional dependencies under the
stated assumptions. Each right-hand side includes all non-key attributes.

| Relation | Dependencies |
| --- | --- |
| `professor` | `pid -> name` |
| `course` | `cid -> coursenumber, unit` |
| `department` | `did -> name, manageby`; `name -> did, manageby` |
| `student` | `sid -> name, dept, unitrequirement` |
| `teach` | `K -> dept` |
| `assignment` | `(K, id) -> weight, duedate` |
| `assign` | `(K, id, sid) -> grade, turnindate` |
| `worksin`, `enroll` | All columns form the primary key; there are no non-key attributes. |

In particular, `dept -> unitrequirement` is not an assumed dependency:
requirements may differ between students in the same department. Likewise,
`(pid, cid, sectionnumber)` does not identify an offering without its term.

## Normalization and update anomalies

Each relation is in 3NF under these dependencies: non-key attributes depend on
the whole key, and every listed nontrivial determinant is a candidate key.
The same dependencies also satisfy BCNF. These claims rely on the documented
business assumptions rather than on attribute names alone.

Professor, student, course, and department descriptions are stored once in
their own relations. An enrollment or assignment result does not repeat a
student's name, department name, or course units, so correcting a description
does not require editing every result row. `worksin` represents multiple
department memberships without repeating professor records. `teach` stores an
offering's department once. `assignment` stores its weight and due date once,
independently of how many students have results. `assign` stores only the
student-specific percentage and submission date.

The composite keys distinguish offerings across terms and multiple assignments
within an offering. Parent rows can exist before dependent rows: for example,
a section can be created before students enroll, and an assignment can be
defined before any grades exist. Student results do not determine the
existence of assignment definitions. GPA and final percentages are derived
instead of being copied into multiple tables and becoming stale after a grade
or weight update.

## Rules beyond ordinary declarative constraints

The `enrollment_grades` SQL view derives total assignment weight, graded weight,
earned percentage points, the current grade, and a final grade when complete.
It is a query over the base relations, not another stored entity or a duplicate
source of grade data. The demonstration queries use this view.

- Assignment weights must total exactly 100 before finalization. Phase 1 permits
  draft schemes and does not enforce the cross-row total in a `CHECK`. The
  Phase 2 application will validate the total in a transaction and lock the
  parent `teach` row for both finalization and assignment edits.
- Final grade/GPA calculations require a complete scheme and recorded results
  for every assignment. The formulas, GPA scale, and repeated-attempt policy
  are defined in [requirements.md](requirements.md).
- What-if values must not overwrite official results. Phase 2 will calculate
  scenarios separately from grade-update operations.
- Students may view their own detailed results and aggregate peer reports.
  Phase 2 must enforce user permissions; table foreign keys do not provide
  application authorization.

## Changes from the supplied draft

The SQL retains the draft's nine relation names and basic structure. `sid`
clarifies the student's identifier; assignment `id` is added to `assign`;
`term` belongs to the offering and all dependent keys; and the offering's
`dept` is a non-key attribute. Grades are decimal percentages, assignment IDs
serve as labels, and the student's unit requirement is individualized. These
choices resolve ambiguities without adding a new application framework or
additional entity tables. They should be reflected in the team's diagram and
reviewed alongside it; no instructor approval is assumed here.
