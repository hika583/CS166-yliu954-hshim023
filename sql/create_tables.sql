-- Run against an empty PostgreSQL database. See README.md.
-- Unquoted names keep the lab-style psql commands simple.
BEGIN;

CREATE TABLE professor (
    pid INTEGER PRIMARY KEY CHECK (pid > 0),
    name TEXT NOT NULL CHECK (name ~ '[^[:space:]]')
);

CREATE TABLE course (
    cid INTEGER PRIMARY KEY CHECK (cid > 0),
    coursenumber INTEGER NOT NULL CHECK (coursenumber > 0),
    unit INTEGER NOT NULL CHECK (unit BETWEEN 1 AND 12)
);

CREATE TABLE department (
    did INTEGER PRIMARY KEY CHECK (did > 0),
    name TEXT NOT NULL UNIQUE CHECK (name ~ '[^[:space:]]'),
    manageby INTEGER NOT NULL
);

CREATE TABLE worksin (
    pid INTEGER NOT NULL REFERENCES professor(pid),
    did INTEGER NOT NULL REFERENCES department(did),
    PRIMARY KEY (pid, did)
);

-- A manager must work in the managed department. Defer this check so a
-- department and its WorksIn membership can be created in one transaction.
ALTER TABLE department ADD CONSTRAINT department_manager_worksin_fkey
    FOREIGN KEY (manageby, did) REFERENCES worksin(pid, did)
    DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE student (
    sid INTEGER PRIMARY KEY CHECK (sid > 0),
    name TEXT NOT NULL CHECK (name ~ '[^[:space:]]'),
    dept INTEGER NOT NULL REFERENCES department(did),
    unitrequirement INTEGER NOT NULL CHECK (unitrequirement BETWEEN 1 AND 300)
);

CREATE TABLE teach (
    pid INTEGER NOT NULL,
    cid INTEGER NOT NULL REFERENCES course(cid),
    sectionnumber INTEGER NOT NULL CHECK (sectionnumber > 0),
    term TEXT NOT NULL CHECK (term ~ '[^[:space:]]'),
    dept INTEGER NOT NULL REFERENCES department(did),
    PRIMARY KEY (pid, cid, sectionnumber, term),
    FOREIGN KEY (pid, dept) REFERENCES worksin(pid, did)
);

CREATE TABLE assignment (
    pid INTEGER NOT NULL,
    cid INTEGER NOT NULL,
    sectionnumber INTEGER NOT NULL,
    term TEXT NOT NULL,
    id INTEGER NOT NULL CHECK (id > 0),
    weight NUMERIC(5,2) NOT NULL CHECK (weight > 0 AND weight <= 100),
    duedate DATE,
    PRIMARY KEY (pid, cid, sectionnumber, term, id),
    FOREIGN KEY (pid, cid, sectionnumber, term)
        REFERENCES teach(pid, cid, sectionnumber, term)
);

CREATE TABLE enroll (
    pid INTEGER NOT NULL,
    cid INTEGER NOT NULL,
    sectionnumber INTEGER NOT NULL,
    term TEXT NOT NULL,
    sid INTEGER NOT NULL REFERENCES student(sid),
    PRIMARY KEY (pid, cid, sectionnumber, term, sid),
    FOREIGN KEY (pid, cid, sectionnumber, term)
        REFERENCES teach(pid, cid, sectionnumber, term)
);

CREATE TABLE assign (
    pid INTEGER NOT NULL,
    cid INTEGER NOT NULL,
    sectionnumber INTEGER NOT NULL,
    term TEXT NOT NULL,
    id INTEGER NOT NULL,
    sid INTEGER NOT NULL,
    grade NUMERIC(5,2) CHECK (grade BETWEEN 0 AND 100),
    turnindate DATE,
    PRIMARY KEY (pid, cid, sectionnumber, term, id, sid),
    FOREIGN KEY (pid, cid, sectionnumber, term, id)
        REFERENCES assignment(pid, cid, sectionnumber, term, id),
    FOREIGN KEY (pid, cid, sectionnumber, term, sid)
        REFERENCES enroll(pid, cid, sectionnumber, term, sid)
);

-- PK indexes already support section/assignment lookups. These indexes
-- support the opposite direction: a student's history and a department's staff.
CREATE INDEX enroll_sid_idx ON enroll(sid);
CREATE INDEX worksin_did_idx ON worksin(did);

-- Derive grades instead of storing totals that can become stale.
CREATE VIEW enrollment_grades AS
WITH totals AS (
    SELECT e.pid, e.cid, e.sectionnumber, e.term, e.sid,
           COALESCE(SUM(a.weight), 0) AS total_weight,
           COALESCE(SUM(CASE WHEN g.grade IS NOT NULL THEN a.weight ELSE 0 END), 0)
               AS graded_weight,
           COALESCE(SUM(COALESCE(g.grade, 0) * a.weight / 100), 0)
               AS earned_percentage
    FROM enroll e
    LEFT JOIN assignment a USING (pid, cid, sectionnumber, term)
    LEFT JOIN assign g ON g.pid = e.pid AND g.cid = e.cid
        AND g.sectionnumber = e.sectionnumber AND g.term = e.term
        AND g.sid = e.sid AND g.id = a.id
    GROUP BY e.pid, e.cid, e.sectionnumber, e.term, e.sid
)
SELECT totals.*,
       ROUND(earned_percentage * 100 / NULLIF(graded_weight, 0), 2) AS current_grade,
       CASE WHEN total_weight = 100 AND graded_weight = 100
            THEN ROUND(earned_percentage, 2) END AS final_grade
FROM totals;

COMMIT;
