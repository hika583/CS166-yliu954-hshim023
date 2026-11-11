# AI use and references

## Assistance in this Phase 1 implementation

OpenAI Codex assisted with reviewing the supplied proposal/schema/diagram,
identifying key ambiguities, writing the PostgreSQL implementation and sample
data, writing these supporting documents, and running database checks.
An additional Codex review checked the SQL and documentation for consistency.
These additions are AI-assisted work, not independently authored student work.

The team supplied the proposal, relational-schema draft, and ER diagram. The
existing diagram image is preserved. The PDF adds written implementation
clarifications; it does not claim a new independently drawn diagram.

Codex tested the scripts in an isolated local PostgreSQL 17.11 instance. Those
automated checks are recorded in [testing.md](testing.md). The students' own
review, modifications, and understanding have not been verified by Codex. Each
team member should record their actual review and contributions before
submission and explain the design in their own words. This statement does not
claim instructor approval of the implementation or this use of AI.

## User task prompt

The project-work portion of the user's prompt was:

> Lets finish the phase 1 my part. my partner has finished the diagram creation
> so do the other part we have to do.
> no need to be fancy. just make it work and also u can use the labs psql
> structure if thats better suited.

The user also supplied the project repository and local course materials.
Account-switching instructions are operational details and are omitted here.

Codex split out two internal review prompts: first, check Phase 1 deliverables,
minimal schema corrections, and integrity-test cases against the supplied
materials; second, review the resulting SQL and design documents for keys,
foreign keys, normalization, grade calculations, and missing cases. The first
review also drafted the two design documents from the agreed schema. Reviews
led to explicit whitespace checks, a documented rounding policy, and completed
records in a second term for the trend report.

## References and data provenance

- Supplied course page: CS 166 Project Description F26, especially Phase 1
  Parts A-D and the deliverable list.
- Team proposal: `cs166 project proposal.pdf`.
- Team draft: `CS166 Project Relational Schema.pdf`.
- Original team diagram in this repository's README at commit `974905d`.
- Supplied `cs166_lab7_updated.zip`: reviewed `startPostgreSQL.sh`,
  `createPostgreDB.sh`, and `create_tables.sql` for the lab's psql workflow.
  No lab dataset is included or required.

All seed names, memberships, enrollments, dates, and grades were hand-written
fictional examples generated for this project. They do not contain real
academic records or come from an external dataset.
