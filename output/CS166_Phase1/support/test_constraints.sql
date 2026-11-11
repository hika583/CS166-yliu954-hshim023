\set ON_ERROR_STOP on
\echo 'Running Phase 1 checks; all test changes will be rolled back.'
BEGIN;
-- Flush the deferred manager FK too, so every loaded record is validated.
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.expect_error(label TEXT, statement TEXT, expected_state TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE actual_state TEXT;
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS actual_state = RETURNED_SQLSTATE;
        IF actual_state <> expected_state THEN
            RAISE EXCEPTION '%: expected SQLSTATE %, got %: %',
                label, expected_state, actual_state, SQLERRM;
        END IF;
        RAISE NOTICE 'PASS: % (SQLSTATE %)', label, actual_state;
        RETURN;
    END;
    RAISE EXCEPTION '%: invalid operation unexpectedly succeeded', label;
END;
$$;

CREATE FUNCTION pg_temp.assert_true(label TEXT, condition BOOLEAN)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'FAIL: %', label;
    END IF;
    RAISE NOTICE 'PASS: %', label;
END;
$$;

SELECT pg_temp.assert_true('all nine tables have expected seed counts',
    (SELECT COUNT(*) = 3 FROM professor) AND (SELECT COUNT(*) = 3 FROM course)
    AND (SELECT COUNT(*) = 2 FROM department) AND (SELECT COUNT(*) = 4 FROM worksin)
    AND (SELECT COUNT(*) = 6 FROM student) AND (SELECT COUNT(*) = 5 FROM teach)
    AND (SELECT COUNT(*) = 11 FROM assignment) AND (SELECT COUNT(*) = 12 FROM enroll)
    AND (SELECT COUNT(*) = 17 FROM assign));

SELECT pg_temp.expect_error('duplicate professor',
    $$INSERT INTO professor VALUES (1, 'Duplicate')$$, '23505');
SELECT pg_temp.expect_error('duplicate department name',
    $$INSERT INTO department VALUES (99, 'Computer Science', 1)$$, '23505');
SELECT pg_temp.expect_error('missing required name',
    $$INSERT INTO student VALUES (999, NULL, 10, 180)$$, '23502');
SELECT pg_temp.expect_error('blank name',
    $$INSERT INTO professor VALUES (99, '   ')$$, '23514');
SELECT pg_temp.expect_error('whitespace-only name',
    $$INSERT INTO professor VALUES (99, E'\t\n')$$, '23514');
SELECT pg_temp.expect_error('invalid identifier',
    $$INSERT INTO professor VALUES (0, 'Invalid')$$, '23514');
SELECT pg_temp.expect_error('missing student department',
    $$INSERT INTO student VALUES (999, 'Test', 999, 180)$$, '23503');
SELECT pg_temp.expect_error('invalid unit requirement',
    $$UPDATE student SET unitrequirement = 0 WHERE sid = 101$$, '23514');
SELECT pg_temp.expect_error('invalid course units',
    $$INSERT INTO course VALUES (999, 999, 0)$$, '23514');
SELECT pg_temp.expect_error('missing professor membership',
    $$INSERT INTO worksin VALUES (999, 10)$$, '23503');
SELECT pg_temp.expect_error('manager outside department',
    $$UPDATE department SET manageby = 3 WHERE did = 10$$, '23503');
SELECT pg_temp.expect_error('teacher outside department',
    $$INSERT INTO teach VALUES (3, 1001, 2, '2026-Fall', 10)$$, '23503');
SELECT pg_temp.expect_error('blank term',
    $$INSERT INTO teach VALUES (1, 1001, 2, ' ', 10)$$, '23514');
SELECT pg_temp.expect_error('invalid section number',
    $$INSERT INTO teach VALUES (1, 1001, 0, '2026-Fall', 10)$$, '23514');
SELECT pg_temp.expect_error('assignment without section',
    $$INSERT INTO assignment VALUES (1, 1001, 99, '2026-Fall', 1, 20, NULL)$$, '23503');
SELECT pg_temp.expect_error('zero assignment weight',
    $$UPDATE assignment SET weight = 0 WHERE pid = 1 AND cid = 1001
      AND term = '2026-Fall' AND id = 1$$, '23514');
SELECT pg_temp.expect_error('assignment weight above 100',
    $$UPDATE assignment SET weight = 100.01 WHERE pid = 1 AND cid = 1001
      AND term = '2026-Fall' AND id = 1$$, '23514');
SELECT pg_temp.expect_error('duplicate enrollment',
    $$INSERT INTO enroll VALUES (1, 1001, 1, '2026-Fall', 101)$$, '23505');
SELECT pg_temp.expect_error('enrollment without student',
    $$INSERT INTO enroll VALUES (1, 1001, 1, '2026-Fall', 999)$$, '23503');
SELECT pg_temp.expect_error('score without assignment',
    $$INSERT INTO assign VALUES (1, 1001, 1, '2026-Fall', 99, 101, 80, NULL)$$, '23503');
SELECT pg_temp.expect_error('score without matching enrollment',
    $$INSERT INTO assign VALUES (1, 1001, 1, '2026-Fall', 1, 105, 80, NULL)$$, '23503');
SELECT pg_temp.expect_error('score linked to wrong term',
    $$INSERT INTO assign VALUES (1, 1001, 1, '2026-Spring', 1, 104, 80, NULL)$$, '23503');
SELECT pg_temp.expect_error('duplicate assignment score',
    $$INSERT INTO assign VALUES (1, 1001, 1, '2026-Fall', 1, 101, 50, NULL)$$, '23505');
SELECT pg_temp.expect_error('negative grade',
    $$UPDATE assign SET grade = -0.01 WHERE sid = 101 AND id = 1$$, '23514');
SELECT pg_temp.expect_error('grade above 100',
    $$UPDATE assign SET grade = 100.01 WHERE sid = 101 AND id = 1$$, '23514');
SELECT pg_temp.expect_error('delete referenced student',
    $$DELETE FROM student WHERE sid = 101$$, '23503');
SELECT pg_temp.expect_error('delete referenced assignment',
    $$DELETE FROM assignment WHERE pid = 1 AND cid = 1001
      AND sectionnumber = 1 AND term = '2026-Fall' AND id = 1$$, '23503');
SELECT pg_temp.expect_error('delete manager membership',
    $$DELETE FROM worksin WHERE pid = 1 AND did = 10$$, '23503');

SELECT pg_temp.assert_true('same section number in separate terms stays distinct',
    (SELECT COUNT(*) = 3 FROM teach WHERE pid = 1 AND cid = 1001 AND sectionnumber = 1));
SELECT pg_temp.assert_true('one student has multiple scores in one section',
    (SELECT COUNT(*) = 2 FROM assign WHERE pid = 1 AND cid = 1001
        AND sectionnumber = 1 AND term = '2026-Fall' AND sid = 101));
SELECT pg_temp.assert_true('zero is graded; NULL is ungraded',
    (SELECT graded_weight = 20 AND current_grade = 0 FROM enrollment_grades
        WHERE pid = 1 AND cid = 1001 AND term = '2026-Fall' AND sid = 103)
    AND (SELECT graded_weight = 0 AND current_grade IS NULL FROM enrollment_grades
        WHERE pid = 1 AND cid = 1001 AND term = '2026-Fall' AND sid = 104));
SELECT pg_temp.assert_true('current grade 86; target 70 needs 54 on remaining work',
    (SELECT current_grade = 86 AND earned_percentage = 43
        AND (70 - earned_percentage) * 100 / (100 - graded_weight) = 54
     FROM enrollment_grades WHERE pid = 1 AND cid = 1001
        AND term = '2026-Fall' AND sid = 101));
SELECT pg_temp.assert_true('completed final grades are 84, 94, and 66',
    (SELECT ARRAY_AGG(final_grade ORDER BY sid) = ARRAY[84,94,66]::NUMERIC[]
     FROM enrollment_grades WHERE term = '2026-Spring'));
SELECT pg_temp.assert_true('no incomplete enrollment gets a final grade',
    NOT EXISTS (SELECT 1 FROM enrollment_grades
                WHERE term = '2026-Fall' AND final_grade IS NOT NULL));
SELECT pg_temp.assert_true('all five sample sections have 100 total assignment weight',
    (SELECT COUNT(*) = 5 AND BOOL_AND(total = 100)
     FROM (SELECT SUM(weight) AS total FROM assignment
           GROUP BY pid, cid, sectionnumber, term) weights));
SELECT pg_temp.assert_true('data includes late, ungraded, missing, and tied scores',
    EXISTS (SELECT 1 FROM assign g JOIN assignment a
            USING (pid, cid, sectionnumber, term, id) WHERE g.turnindate > a.duedate)
    AND EXISTS (SELECT 1 FROM assign WHERE grade IS NULL AND turnindate IS NOT NULL)
    AND NOT EXISTS (SELECT 1 FROM assign WHERE sid = 106)
    AND (SELECT COUNT(*) = 2 FROM assign WHERE cid = 1002 AND grade = 85.5));

UPDATE assignment SET weight = 40 WHERE pid = 1 AND cid = 1001
    AND sectionnumber = 1 AND term = '2025-Fall' AND id = 1;
SELECT pg_temp.assert_true('draft weight total does not produce a final grade',
    (SELECT total_weight = 90 AND final_grade IS NULL FROM enrollment_grades
     WHERE pid = 1 AND cid = 1001 AND term = '2025-Fall' AND sid = 101));
UPDATE assignment SET weight = 60 WHERE pid = 1 AND cid = 1001
    AND sectionnumber = 1 AND term = '2025-Fall' AND id = 1;
SELECT pg_temp.assert_true('overweight scheme does not produce a final grade',
    (SELECT total_weight = 110 AND final_grade IS NULL FROM enrollment_grades
     WHERE pid = 1 AND cid = 1001 AND term = '2025-Fall' AND sid = 101));
UPDATE assignment SET weight = 50 WHERE pid = 1 AND cid = 1001
    AND sectionnumber = 1 AND term = '2025-Fall' AND id = 1;

-- Successful insert/update/delete, including the deferred circular membership.
SET CONSTRAINTS department_manager_worksin_fkey DEFERRED;
INSERT INTO professor VALUES (99, 'Temporary Professor');
INSERT INTO department VALUES (99, 'Temporary Department', 99);
INSERT INTO worksin VALUES (99, 99);
SET CONSTRAINTS department_manager_worksin_fkey IMMEDIATE;
INSERT INTO student VALUES (999, 'Temporary Student', 99, 180);
UPDATE student SET name = 'Updated Student' WHERE sid = 999;
SELECT pg_temp.assert_true('valid insert and update',
    (SELECT name = 'Updated Student' FROM student WHERE sid = 999));
DELETE FROM student WHERE sid = 999;
SELECT pg_temp.assert_true('delete unreferenced record',
    NOT EXISTS (SELECT 1 FROM student WHERE sid = 999));

-- Failed statements above run in subtransactions. Their partial effects roll back.
SELECT pg_temp.assert_true('failed grade updates left the original scores intact',
    (SELECT COUNT(*) = 17 FROM assign)
    AND (SELECT grade = 80 FROM assign WHERE pid = 1 AND cid = 1001
         AND sectionnumber = 1 AND term = '2026-Fall' AND id = 1 AND sid = 101));

ROLLBACK;
\echo 'All Phase 1 checks passed. Test changes rolled back.'
