# CS166 Project - Grade Database

Phase 1 includes the database, sample data, and design documents.

## Files

- [Requirements](docs/requirements.md)
- [ER diagram PDF](output/pdf/er-diagram.pdf)
- [Relational schema and normalization](docs/relational-schema.md)
- [Create tables](sql/create_tables.sql)
- [Sample data](sql/sample_data.sql)
- [Testing notes](docs/testing.md)

## Run

Use an empty PostgreSQL database. Run these from the project folder:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f sql/queries.sql
```

The load script creates the tables and inserts the data. The test script rolls
back its changes. Use a different database name to load another copy.

## CS166 lab

Start the lab database if needed, then open psql:

```sh
cs166_db_start
cs166_createdb "${USER}_project_DB"
cs166_psql "${USER}_project_DB"
```

Inside psql, from the project folder:

```sql
\i sql/load.sql
\i sql/test_constraints.sql
\i sql/queries.sql
```

Tested locally with PostgreSQL 17.11. The lab commands follow Lab 7.
Java/JDBC and the GUI are for Phase 2.

## ER diagram

![ER diagram](docs/er-diagram.png)

The PDF includes notes on the section term, assignment ID, and student ID used
in the SQL.
