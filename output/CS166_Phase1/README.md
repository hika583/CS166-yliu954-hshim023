# CS166 Phase 1 - Grade Database

## Deliverables

1. Requirements: 01_Requirements.pdf
2. ER diagram: 02_ER_Diagram.pdf
3. Relational schema: 03_Relational_Schema.pdf
4. Database creation: create_tables.sql
5. Sample data: sample_data.sql
6. Testing notes: 06_Testing_Notes.pdf

## Run

Use a running PostgreSQL server. From this folder:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/queries.sql
```

Use an empty database, or choose a different database name. load.sql runs the
creation and sample-data scripts in order. The tests roll back their changes.

Tested on PostgreSQL 17.11. Recorded output is in support/test-results.txt.
