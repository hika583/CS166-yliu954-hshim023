-- Fictional sample data for the grade database.
-- This file is intended to be loaded once after create_tables.sql.
BEGIN;

INSERT INTO professor (pid, name) VALUES
    (1, 'Ada Moreno'), (2, 'Ben Patel'), (3, 'Chen Wu');

INSERT INTO course (cid, coursenumber, unit) VALUES
    (1001, 166, 4), (1002, 141, 4), (2001, 9, 4);

INSERT INTO department (did, name, manageby) VALUES
    (10, 'Computer Science', 1), (20, 'Mathematics', 3);

INSERT INTO worksin (pid, did) VALUES
    (1, 10), (2, 10), (2, 20), (3, 20);

INSERT INTO student (sid, name, dept, unitrequirement) VALUES
    (101, 'Alex Rivera', 10, 180),
    (102, 'Morgan Lee', 10, 180),
    (103, 'Sam Taylor', 10, 180),
    (104, 'Jamie Park', 10, 176),
    (105, 'Casey Stone', 20, 180),
    (106, 'Riley Chen', 10, 180);

INSERT INTO teach (pid, cid, sectionnumber, term, dept) VALUES
    (1, 1001, 1, '2025-Fall', 10),
    (1, 1001, 1, '2026-Spring', 10),
    (1, 1001, 1, '2026-Fall', 10),
    (2, 1002, 1, '2026-Fall', 10),
    (3, 2001, 1, '2026-Fall', 20);

INSERT INTO assignment (pid, cid, sectionnumber, term, id, weight, duedate) VALUES
    (1, 1001, 1, '2025-Fall', 1, 50, '2025-10-15'),
    (1, 1001, 1, '2025-Fall', 2, 50, '2025-12-01'),
    (1, 1001, 1, '2026-Spring', 1, 40, '2026-04-15'),
    (1, 1001, 1, '2026-Spring', 2, 60, '2026-06-01'),
    (1, 1001, 1, '2026-Fall', 1, 20, '2026-10-15'),
    (1, 1001, 1, '2026-Fall', 2, 30, '2026-11-01'),
    (1, 1001, 1, '2026-Fall', 3, 50, '2026-12-05'),
    (2, 1002, 1, '2026-Fall', 1, 50, '2026-10-20'),
    (2, 1002, 1, '2026-Fall', 2, 50, '2026-12-02'),
    (3, 2001, 1, '2026-Fall', 1, 25, '2026-10-25'),
    (3, 2001, 1, '2026-Fall', 2, 75, NULL);

INSERT INTO enroll (pid, cid, sectionnumber, term, sid) VALUES
    (1, 1001, 1, '2025-Fall', 101),
    (1, 1001, 1, '2026-Spring', 101),
    (1, 1001, 1, '2026-Spring', 102),
    (1, 1001, 1, '2026-Spring', 103),
    (1, 1001, 1, '2026-Fall', 101),
    (1, 1001, 1, '2026-Fall', 102),
    (1, 1001, 1, '2026-Fall', 103),
    (1, 1001, 1, '2026-Fall', 104),
    (1, 1001, 1, '2026-Fall', 106),
    (2, 1002, 1, '2026-Fall', 101),
    (2, 1002, 1, '2026-Fall', 102),
    (3, 2001, 1, '2026-Fall', 105);

INSERT INTO assign (pid, cid, sectionnumber, term, id, sid, grade, turnindate) VALUES
    (1, 1001, 1, '2025-Fall', 1, 101, 70, '2025-10-15'),
    (1, 1001, 1, '2025-Fall', 2, 101, 80, '2025-12-01'),
    (1, 1001, 1, '2026-Spring', 1, 101, 90, '2026-04-14'),
    (1, 1001, 1, '2026-Spring', 2, 101, 80, '2026-06-01'),
    (1, 1001, 1, '2026-Spring', 1, 102, 100, '2026-04-15'),
    (1, 1001, 1, '2026-Spring', 2, 102, 90, '2026-06-01'),
    (1, 1001, 1, '2026-Spring', 1, 103, 60, '2026-04-16'),
    (1, 1001, 1, '2026-Spring', 2, 103, 70, '2026-06-01'),
    (1, 1001, 1, '2026-Fall', 1, 101, 80, '2026-10-15'),
    (1, 1001, 1, '2026-Fall', 2, 101, 90, '2026-11-02'),
    (1, 1001, 1, '2026-Fall', 1, 102, 100, '2026-10-14'),
    (1, 1001, 1, '2026-Fall', 2, 102, 100, '2026-11-01'),
    (1, 1001, 1, '2026-Fall', 1, 103, 0, '2026-10-15'),
    (1, 1001, 1, '2026-Fall', 2, 104, NULL, '2026-11-01'),
    (2, 1002, 1, '2026-Fall', 1, 101, 85.5, '2026-10-20'),
    (2, 1002, 1, '2026-Fall', 1, 102, 85.5, '2026-10-21'),
    (3, 2001, 1, '2026-Fall', 1, 105, 72, '2026-10-25');

COMMIT;
