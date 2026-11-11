# Phase 1 testing notes

## Environment and result

Validated on November 11, 2026 with PostgreSQL 17.11 (Homebrew).
The server used a temporary local data directory and a private Unix socket.
It did not connect to an existing database or use Docker. The temporary server
was stopped after testing.

The load, constraint checks, and all eight report queries succeeded in two
separately created empty databases, `cs166_project` and `cs166_repeat`.
Each database passed 42 checks. A separate transaction also confirmed that an
invalid deferred manager membership fails at commit with SQLSTATE `23503`,
and that the entire transaction rolls back.

The actual command output and query results are in
[test-results.txt](test-results.txt). This is local evidence; the course-hosted
PostgreSQL environment and its shell wrappers were not executed.

## Reproduce

From the repository root, against a running PostgreSQL server:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/queries.sql
```

Use a new database name if that database already exists. `test_constraints.sql`
reports each successful check with `PASS`, fails on unexpected behavior, and
rolls back its test changes. `ON_ERROR_STOP` gives a nonzero exit status if an
unexpected SQL error occurs. The scripts use PostgreSQL/psql features, including
PL/pgSQL test helpers; they are not intended for another DBMS.

## Sample data coverage

| Relation | Rows |
| --- | ---: |
| professor | 3 |
| course | 3 |
| department | 2 |
| worksin | 4 |
| student | 6 |
| teach | 5 |
| assignment | 11 |
| enroll | 12 |
| assign | 17 |

The hand-written fictional data includes three terms, repeated section numbers,
multiple department memberships, different assignment weights, decimal grades,
zero and 100 grades, missing results, a submitted but ungraded assignment, an
assignment without a due date, late/on-time submissions, assignments without
results, students without grades, and tied scores. All five seeded sections
have a complete 100-weight assignment scheme.

## Integrity and operation checks

- Duplicate professor IDs, department names, enrollments, and assignment results
  are rejected (`23505`).
- A required NULL name is rejected (`23502`); blank/whitespace-only names,
  invalid identifiers, units, requirements, sections, weights, terms, and
  out-of-range grades are rejected (`23514`).
- Invalid departments, professors, sections, assignments, enrollments, manager
  memberships, teacher memberships, and cross-term result references are
  rejected (`23503`).
- Deleting referenced students, assignments, or manager memberships is rejected.
- A student can have multiple assignment results in one offering. The same
  professor/course/section number remains distinct in separate terms.
- Valid inserts, updates, and deletion of an unreferenced student succeed.
- A department and its manager membership can be created together using the
  deferred FK. Missing membership at commit rejects the whole transaction.
- Zero grades participate in calculations; ungraded/missing work stays unknown.
- Draft totals of 90 and invalid totals of 110 do not produce final grades.
  Cross-row weight totals are deliberately not rejected by a row-level CHECK;
  the Phase 2 finalization rule is documented in the requirements.
- Failed updates leave original grades intact, and all test-created records
  disappear after rollback. The post-test counts confirm that the sample data
  remains unchanged.

## Representative query results

| Example | Actual result |
| --- | --- |
| Student 101, Fall CS166 current grade | 86.00% from 43 earned points over 50 graded weight |
| Student 101, average needed on remaining work for 70% | 54.00% |
| Student 101, 90% on remaining Fall CS166 work | Projected final 88.00% |
| Spring CS166 completed finals, ordered by student | 101: 84.00%; 102: 94.00%; 103: 66.00% |
| Fall CS166 enrollments with no recorded grades | Students 104 and 106 |
| Fall CS166 assignment 1 | Min 0.00%, max 100.00%, average 60.00% |
| Fall CS166 assignment 3 | Zero graded results; min/max/average are NULL |
| Completed-course GPA | 101: 2.50; 102: 4.00; 103: 1.00 |
| Professor 1 completed-result averages | 2025-Fall: 75.00%; 2026-Spring: 81.33% |

The reports demonstrate joins, grouping/aggregation, a correlated `NOT EXISTS`,
an all-assignments-complete condition, ranking, grade projection, GPA, and an
aggregate distribution without peer names or IDs. These small records validate
functionality; they do not establish an index performance improvement.

## Phase 2 boundaries

The Java/JDBC GUI, authentication, application permissions, grading-scheme
finalization with serialized assignment edits, and larger-data index analysis
remain Phase 2 work. These results do not claim that those workflows have been
implemented or tested.
