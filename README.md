# CS166-yliu954-hshim023
CS166 Project - Grade Database

Phase 1: PostgreSQL schema, fictional sample data, design documentation, and
constraint checks. The Java/JDBC GUI is Phase 2 work.

## Phase 1 files

- [Requirements and business rules](docs/requirements.md)
- [ER diagram PDF](output/pdf/er-diagram.pdf) - original team diagram plus a page
  explaining the key/attribute clarifications used by the SQL
- [Relational schema, keys, functional dependencies, and 3NF](docs/relational-schema.md)
- [Database creation script](sql/create_tables.sql)
- [Sample data](sql/sample_data.sql)
- [Testing notes and results](docs/testing.md)
- [AI use and project references](docs/AI_USE.md)

## Run with PostgreSQL

Use a running PostgreSQL server and its `createdb`/`psql` commands. Tested on
PostgreSQL 17.11. No Java dependencies are needed for Phase 1.

From the repository root:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/queries.sql
```

`load.sql` creates the nine tables, two supporting indexes, one grade-calculation
view, and the sample records. It must run on an empty database. It does not drop
existing tables. To load another copy, create a different database and replace
`cs166_project` in the commands. The tests roll back all their changes.

Connection settings can use the normal `PGHOST`, `PGPORT`, and `PGUSER`
environment variables. No password is stored in this repository.

## Run in the CS166 lab environment

This follows Lab 7's PostgreSQL workflow. If your lab provides the same helpers:

```sh
cs166_initdb
cs166_db_start
cs166_createdb "${USER}_project_DB"
cs166_psql "${USER}_project_DB" -v ON_ERROR_STOP=1 -f sql/load.sql
cs166_psql "${USER}_project_DB" -v ON_ERROR_STOP=1 -f sql/test_constraints.sql
cs166_psql "${USER}_project_DB" -v ON_ERROR_STOP=1 -f sql/queries.sql
```

Only initialize the lab cluster if it has not already been initialized. If the
lab wrapper does not forward command-line options, enter `cs166_psql
"${USER}_project_DB"` interactively and run `\i sql/load.sql`, then
`\i sql/test_constraints.sql` and `\i sql/queries.sql`.

The lab helpers were read from the supplied archive; this run tested the SQL
with standard local PostgreSQL, not the course server.

## Design notes

The SQL keeps the draft's table names. A section key includes its term, and each
student result includes an assignment ID and references a matching enrollment.
The student identifier is `sid`. Grades are percentages, and assignment IDs act
as labels. See the schema document and PDF's clarification page for the mapping
from the original diagram.

Assignment weights must total 100 before finalization. Phase 1 permits draft
schemes; the view only produces final grades for complete 100-weight schemes
with all results recorded. Phase 2 must validate and serialize assignment edits
when finalizing a grading scheme, and enforce user access to grades.

## Original team ER diagram

![Original team ER diagram](docs/er-diagram.png)
