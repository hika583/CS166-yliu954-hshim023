# Testing notes

Tested on November 11, 2026 with PostgreSQL 17.11.

The tables and sample data loaded in two empty databases. Both runs passed all
42 checks and all 8 example queries. The manager foreign key also rejected an
invalid transaction at commit and rolled back the whole transaction.

Full output: [test-results.txt](test-results.txt).

## Run the checks

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/queries.sql
```

Use another name if the database already exists. The tests roll back their
changes, so the sample data stays the same.

## Sample data

| Table | Rows |
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

Sample rows use fictional names and fixed dates/scores, entered directly in
`sample_data.sql`. They cover three terms, repeated sections, multiple
department memberships, late submissions, missing and ungraded work, tied
scores, and grades of 0 and 100. Each sample section has 100 total weight.

## What was checked

- Duplicate keys, missing required values, and invalid names or numbers fail.
- Grades outside 0-100 and weights outside 0-100 fail. Weight cannot be zero.
- Foreign keys reject missing parents and scores for unenrolled students.
- Managers and section professors must work in the correct department.
- Referenced records cannot be deleted.
- Valid inserts, updates, and deletes work.
- Terms keep repeated sections separate. One student can have multiple grades
  in the same section.
- Zero counts as a grade. NULL means ungraded.
- Totals of 90 or 110 do not produce a final grade.
- Failed transactions and the test script leave the sample data unchanged.

## Example results

| Query | Result |
| --- | --- |
| Student 101, Fall CS166 current grade | 86.00% |
| Average needed on remaining work to finish with 70% | 54.00% |
| Final projection with 90% on remaining work | 88.00% |
| Spring CS166 final grades | 101: 84%; 102: 94%; 103: 66% |
| Fall CS166 students with no grades | 104 and 106 |
| Fall CS166 assignment 1 min/max/average | 0% / 100% / 60% |
| GPA | 101: 2.50; 102: 4.00; 103: 1.00 |
| Professor 1 average by term | 2025-Fall: 75%; 2026-Spring: 81.33% |

The SQL was tested locally, not on the course server. GUI testing, permissions,
and index performance testing are for Phase 2.
