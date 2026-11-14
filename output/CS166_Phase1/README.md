# CS166 Phase 1

Phase1_Report.pdf combines the requirements, relational schema, and testing
notes, including screenshots. ER_Diagram.pdf is the original teammate diagram.
create_tables.sql creates the schema; sample_data.sql inserts the sample rows.

From this folder, with PostgreSQL running:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/queries.sql
```

Use an empty database. Tests roll back their changes. Logs and screenshots are
in support. The screenshots show actual psql output displayed in a local page.
