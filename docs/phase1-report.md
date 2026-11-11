# CS166 Project Phase 1

## 1 Requirements

This project stores courses, assignments, and student grades in PostgreSQL.
Students can check results and estimate grades. Professors can record
grades and compare results. The Java/JDBC application is for Phase 2.

Teach represents a section. WorksIn, Enroll, and Assign store department
memberships, enrollments, and results.

Relationships:

- Professors can work in multiple departments or none. Each department has at
  least its manager as a member. Each department has one manager; a professor
  can manage multiple departments.
- Each student belongs to one department. A department can have many students
  or none.
- Each section has one professor, course, and department. Each of those parents
  can have many sections or none. The professor must work in that department.
- A section can have many assignments or none. Each assignment belongs to one
  section.
- Students and sections have a many-to-many relationship through Enroll.
  Neither side needs an enrollment yet.
- Students and assignments have a many-to-many relationship through Assign.
  Each result must match an assignment and an enrollment in the same section.
  An enrollment or assignment can have no results yet.

The application will add, search, update, and delete records. Queries include
a student's courses and assignments, current and projected grades,
scores needed for a target grade, assignment statistics and
distributions, students with no grades, GPA, professor results by term, and late
submissions. Peer comparisons show summaries rather than other students' names.

Grades are percentages from 0 to 100. NULL or a missing result means ungraded;
zero is a recorded grade. Dates can be unknown. Assignment IDs are local to a
section and serve as labels. Names and course numbers can repeat. Graduation
unit requirements can differ between students in the same department.

Assignment weights must total 100 before finalizing a grade. Phase 2 will check
this cross-row total while locking Teach during changes/finalization. Drafts can be incomplete.
What-if calculations do not overwrite recorded grades.

For graded work, current grade is `100 * SUM(grade * weight / 100) / SUM(weight)`.
With no graded work it is unknown. Final grades require total weight 100 and
all assignments graded. GPA uses rounded final percentages: A=4 at 90+, B=3 at
80+, C=2 at 70+, D=1 at 60+, and F=0. It is weighted by course units. All completed
attempts count; there are no plus/minus grades.

## 2 Relational schema

`K = (pid, cid, sectionnumber, term)` is the section key. Below, K expands to those columns.

- `professor(pid, name)` - PK: pid.
- `course(cid, coursenumber, unit)` - PK: cid.
- `department(did, name, manageby)` - PK: did. Alternate key: name.
  FK: (manageby, did) references worksin(pid, did).
- `student(sid, name, dept, unitrequirement)` - PK: sid.
  FK: dept references department(did).
- `worksin(pid, did)` - PK: (pid, did).
  FKs: pid references professor(pid); did references department(did).
- `teach(K, dept)` - PK: K. FKs: cid references course(cid);
  (pid, dept) references worksin(pid, did).
- `assignment(K, id, weight, duedate)` - PK: (K, id).
  FK: K references teach(K).
- `enroll(K, sid)` - PK: (K, sid).
  FKs: K references teach(K); sid references student(sid).
- `assign(K, id, sid, grade, turnindate)` - PK: (K, id, sid).
  FKs: (K, id) references assignment(K, id); (K, sid) references enroll(K, sid).

In SQL, the student ID is sid, section term
replaces the enrollment-only termEnrolled, and Assign includes assignment id.
This separates repeated sections and results for different assignments.
Department is determined by the section key.

IDs and section numbers are positive integers. Names and terms cannot be blank.
Course units are 1-12 and individual unit requirements are 1-300. Weights and
grades use NUMERIC(5,2); weights are greater than 0 and at most 100. Dates use
DATE. Only duedate, grade, and turnindate allow NULL. Department name is the only
additional candidate key. Referenced records cannot be deleted. The manager FK
is deferred until commit so a department and its membership can be inserted in
one transaction.

The functional dependencies are:

- professor: pid -> name.
- course: cid -> coursenumber, unit.
- department: did -> name, manageby; name -> did, manageby.
- student: sid -> name, dept, unitrequirement.
- teach: K -> dept.
- assignment: (K, id) -> weight, duedate.
- assign: (K, id, sid) -> grade, turnindate.
- worksin and enroll contain only their key columns.

These dependencies satisfy 3NF. Non-key attributes depend on the full key;
there is no dependency such as dept -> unitrequirement. Names are stored once.
Assignment details are separate from results, so changing a weight requires one
update. Sections can exist before enrollment; deleting a result keeps its assignment.
GPA and grade totals are calculated rather than stored. The enroll_sid_idx and
worksin_did_idx indexes support student-history and department-staff lookups.

## 3 Testing

The scripts loaded successfully in two empty PostgreSQL 17.11 databases. Each
run passed 42 checks and all eight example queries. An invalid manager
membership also failed at commit and rolled back the transaction. The test
script rolls back its own changes. The screenshots show psql output from a
fresh run, displayed in a local browser page.

[Screenshot: database load]

The checks cover duplicate keys, missing required fields, invalid numbers,
foreign keys, and deletion of referenced records. They also check valid
inserts/updates/deletes, repeated sections across terms, multiple assignment
results per student, zero versus NULL grades, and incomplete weight totals.

[Screenshot: constraint checks]

Sample rows use fictional names and fixed dates and scores, entered directly
in sample_data.sql. There are 3 professors, 3 courses, 2 departments, 4
memberships, 6 students, 5 sections, 11 assignments, 12 enrollments, and 17
results. They include late submissions, missing and ungraded work, tied scores,
and grades of 0 and 100.

For student 101 in Fall CS166, the current grade is 86%. An average of 54% on
the remaining work reaches a final grade of 70%; a remaining average of 90%
projects to 88%. Students 104 and 106 have no recorded grades. The Spring
CS166 final grades are 84%, 94%, and 66% for students 101, 102, and 103.

[Screenshot: query results]

Run from the submission folder:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/queries.sql
```

Use an empty database or another name. Full output is in support/test-results.txt
and support/screenshot-output.txt.
