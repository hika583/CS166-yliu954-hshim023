# Phase 1 requirements

## Purpose and users

The Grade Database stores fictional university course, enrollment, assignment,
and grade records. Students will use it to inspect their own results and estimate
grades. Professors will enter results and view summaries for their sections.
The project uses PostgreSQL. The Java/JDBC application and GUI are Phase 2 work.

## Information stored

| Entity or association | Attributes |
| --- | --- |
| Professor | `pid`, `name` |
| Course | `cid`, `coursenumber`, `unit` |
| Department | `did`, `name`, `manageby` |
| Student | `sid`, `name`, `dept`, `unitrequirement` |
| WorksIn | `pid`, `did` |
| Teach (one section offering) | `pid`, `cid`, `sectionnumber`, `term`, `dept` |
| Assignment | section key, assignment `id`, `weight`, `duedate` |
| Enroll | section key, `sid` |
| Assign (one student's assignment result) | section key, assignment `id`, `sid`, `grade`, `turnindate` |

The section key is `(pid, cid, sectionnumber, term)`. An assignment ID is local
to that section and also serves as its label. All grades are percentages; the
database does not need an assignment's maximum points to interpret them.

## Relationships and participation

| Association | Cardinality and participation |
| --- | --- |
| Professor works in Department | Many-to-many through `worksin`; a professor may work in zero or more departments. |
| Professor manages Department | Each department has exactly one manager; a professor may manage zero or more departments. The manager must work in that department. |
| Student belongs to Department | Each student has exactly one department; a department may have zero or more students. |
| Professor teaches section | Each `teach` offering has exactly one professor; a professor may have zero or more offerings. |
| Course has section | Each offering refers to exactly one course; a course may have zero or more offerings. |
| Department offers section | Each offering belongs to exactly one department; a department may offer zero or more sections. Its professor must work in that department. |
| Section contains Assignment | Each assignment belongs to exactly one offering; an offering may have zero or more assignments while its grading scheme is being prepared. |
| Student participates in Enroll | Each enrollment has one student; a student may have zero or more enrollments. |
| Section participates in Enroll | Each enrollment has one offering; an offering may have zero or more enrollments. Students and offerings are many-to-many. |
| Enroll has assignment results | Each `assign` row belongs to one enrollment; an enrollment may have zero or more results. |
| Assignment has student results | Each `assign` row belongs to one assignment; an assignment may have zero or more results. Students and assignments are many-to-many within an offering. |

A missing `assign` row means no result record exists. A row with a NULL grade
means its grade is not recorded yet. A grade of zero is a recorded result and
must participate in calculations. A NULL submission date means the submission
date is unknown or not applicable; a NULL due date means no due date is set.

## Integrity rules

- IDs and section numbers are positive integers. Names and terms are nonblank.
- Department names are unique. Student/professor names and course numbers need
  not be unique. Courses are identified by `cid`.
- Course units are 1 through 12. A student's individual unit requirement is 1
  through 300; students in the same department may have different requirements.
- Assignment weights are greater than zero and at most 100. Recorded grades
  range from 0 through 100, including fractional percentages.
- A student has at most one enrollment in a particular offering and at most one
  result for each assignment in that offering.
- An assignment result must refer both to an existing assignment and to an
  enrollment in the same offering.
- Referenced records cannot be deleted until their dependent records have been
  handled explicitly. Deletion does not silently erase grades or enrollments.
- Departments and their manager memberships are created in one transaction.
  The manager's `worksin` row must exist when the transaction commits.

Assignment weights must total exactly 100 before a grading scheme is finalized.
Phase 1 permits incomplete draft schemes; a row-level `CHECK` cannot enforce
this total across assignments. In Phase 2, finalization will check the total in
a transaction, and assignment edits/finalization will lock the parent `teach`
row so concurrent changes cannot bypass the check.

## Planned operations and reports

The Phase 2 application will support inserting, finding, updating, and deleting
appropriate students, professors, courses, sections, assignments, enrollments,
and results, subject to these constraints. It will provide:

1. Enrollment and assignment listings for a selected student and term.
2. Current weighted grades, remaining work, what-if grades, and the average
   percentage needed on remaining work to reach a target grade.
3. Assignment minimum, maximum, average, and grade distributions.
4. Students with no recorded grades, using a missing-record query.
5. Unit-weighted GPA from completed offerings.
6. Professor grade trends across courses and terms, including ordered results.
7. Late-submission summaries when both due and submission dates are available.

The current grade divides earned weighted points by the sum of weights with
recorded grades. With no recorded weight it is unknown, not zero. A projected
final grade or target calculation requires a complete 100-weight scheme; if no
weight remains, the application reports the recorded final result instead of
dividing by zero. A required remaining score above 100 is reported as
unachievable under that scenario. What-if calculations do not modify official
results.

For this project, an offering is complete for a student when its assignment
weights total 100 and every assignment has a recorded grade for that student.
The final percentage is the sum of `grade * weight / 100`, rounded to two decimal
places before applying the GPA thresholds. The simple GPA scale
is A = 4 for at least 90, B = 3 for at least 80, C = 2 for at least 70, D = 1 for
at least 60, and F = 0 below 60. GPA is the unit-weighted mean of those points.
There are no plus/minus grades; all completed repeated attempts count. An empty
completed-course set has no GPA. Final grades and GPA are computed, not stored.

Student-facing peer comparisons will show aggregates without individual peer
names or IDs. Authentication and access control belong to the Phase 2
application; the Phase 1 schema alone does not enforce those viewing rules.

## Assumptions and design clarifications

The proposal and supplied ER/schema drafts are design references, not evidence
of instructor approval. These implementation clarifications need to remain
consistent with the team's submitted diagram:

- The student identifier is `sid`; the diagram's student `PID` label is treated
  as a typo.
- A term belongs to the section offering and is part of its key and dependent
  keys. This distinguishes the same course/section taught in different terms;
  a redundant enrollment-only `termEnrolled` attribute is unnecessary.
- `Assign` includes assignment `id` so each result identifies a particular
  assignment, rather than only a student and section.
- `dept` is determined by an offering and is not an additional part of its
  primary key. Section numbers are scoped to professor, course, and term.
- Each offering has one professor; co-teaching is outside this simplified model.
- Assignment IDs are sufficient labels for Phase 1, and grades are percentages.
- Sample records are synthetic. No real student academic records are required.
