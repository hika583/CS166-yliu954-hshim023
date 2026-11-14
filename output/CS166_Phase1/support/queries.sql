\set ON_ERROR_STOP on
\pset null '(none)'

\echo '1. Alex (101): enrolled courses, professor, department, and term'
SELECT e.sid, s.name, c.coursenumber, p.name AS professor,
       d.name AS department, e.sectionnumber, e.term
FROM enroll e
JOIN student s USING (sid)
JOIN course c USING (cid)
JOIN professor p USING (pid)
JOIN teach t USING (pid, cid, sectionnumber, term)
JOIN department d ON d.did = t.dept
WHERE e.sid = 101
ORDER BY e.term, c.coursenumber;

\echo '2. Current grade, average needed for 70%, and a 90%-remaining what-if'
-- Missing/ungraded work remains unknown. It is not treated as an official zero.
-- These calculations only apply to a complete 100% assignment-weight scheme.
SELECT sid, current_grade, earned_percentage, graded_weight,
       CASE WHEN total_weight = 100 AND graded_weight < 100
            THEN ROUND((70 - earned_percentage) * 100 / (100 - graded_weight), 2)
       END AS average_needed_for_70,
       CASE WHEN total_weight = 100
            THEN ROUND(earned_percentage + 0.90 * (100 - graded_weight), 2)
       END AS projected_with_90_remaining
FROM enrollment_grades
WHERE pid = 1 AND cid = 1001 AND sectionnumber = 1 AND term = '2026-Fall'
ORDER BY sid;
-- A needed average <= 0 means the target is already secured;
-- > 100 means it is unreachable under this grading model.

\echo '3. Assignment statistics, including assignments with no grades'
SELECT a.pid, a.cid, a.sectionnumber, a.term, a.id,
       COUNT(g.grade) AS graded_count,
       MIN(g.grade) AS minimum, MAX(g.grade) AS maximum,
       ROUND(AVG(g.grade), 2) AS average,
       COUNT(*) FILTER (WHERE g.turnindate > a.duedate) AS late_submissions
FROM assignment a
LEFT JOIN assign g USING (pid, cid, sectionnumber, term, id)
GROUP BY a.pid, a.cid, a.sectionnumber, a.term, a.id
ORDER BY a.pid, a.cid, a.sectionnumber, a.term, a.id;

\echo '4. Fall CS166 enrollments with no recorded grades (NOT EXISTS)'
SELECT e.sid, s.name
FROM enroll e JOIN student s USING (sid)
WHERE e.pid = 1 AND e.cid = 1001 AND e.sectionnumber = 1 AND e.term = '2026-Fall'
  AND NOT EXISTS (
      SELECT 1 FROM assign g
      WHERE g.pid = e.pid AND g.cid = e.cid AND g.sectionnumber = e.sectionnumber
        AND g.term = e.term AND g.sid = e.sid AND g.grade IS NOT NULL
  )
ORDER BY e.sid;

\echo '5. Enrollments graded on every assignment, ranked by final percentage'
SELECT sid, pid, cid, sectionnumber, term, final_grade,
       DENSE_RANK() OVER (ORDER BY final_grade DESC) AS grade_rank
FROM enrollment_grades
WHERE final_grade IS NOT NULL
ORDER BY grade_rank, sid;

\echo '6. Credit-weighted GPA from completed enrollments'
-- Simplified project scale: A=4 (>=90), B=3 (>=80), C=2 (>=70), D=1 (>=60), F=0.
-- All completed attempts count. Incomplete courses are excluded.
SELECT s.sid, s.name, SUM(c.unit) AS completed_units,
       ROUND(SUM(c.unit * CASE WHEN g.final_grade >= 90 THEN 4.0
                              WHEN g.final_grade >= 80 THEN 3.0
                              WHEN g.final_grade >= 70 THEN 2.0
                              WHEN g.final_grade >= 60 THEN 1.0 ELSE 0.0 END)
             / SUM(c.unit), 2) AS gpa
FROM enrollment_grades g
JOIN student s USING (sid) JOIN course c USING (cid)
WHERE g.final_grade IS NOT NULL
GROUP BY s.sid, s.name
ORDER BY s.sid;

\echo '7. Professor/term summary of completed course results'
SELECT p.pid, p.name, g.term, COUNT(*) AS completed_enrollments,
       ROUND(AVG(g.final_grade), 2) AS average_final_grade,
       MIN(g.final_grade) AS minimum, MAX(g.final_grade) AS maximum
FROM enrollment_grades g JOIN professor p USING (pid)
WHERE g.final_grade IS NOT NULL
GROUP BY p.pid, p.name, g.term
ORDER BY p.pid, g.term;

\echo '8. Aggregate grade distribution for Fall CS166 assignment 1'
-- Only counts are returned: peer student identities are omitted.
SELECT CASE WHEN grade >= 90 THEN 'A: 90-100'
            WHEN grade >= 80 THEN 'B: 80-89.99'
            WHEN grade >= 70 THEN 'C: 70-79.99'
            WHEN grade >= 60 THEN 'D: 60-69.99'
            ELSE 'F: below 60' END AS grade_band,
       COUNT(*) AS students
FROM assign
WHERE pid = 1 AND cid = 1001 AND sectionnumber = 1 AND term = '2026-Fall'
  AND id = 1 AND grade IS NOT NULL
GROUP BY grade_band ORDER BY grade_band;
