# ATS010 - KCA: Applying Policies

Kyverno Certified Associate (KCA), domain Applying Policies. Every lab and playground runs on a kind cluster with Kyverno v1.13.2 installed by its bootstrap script. All labs are UNTESTED: built from static checks only, never booted.

## Layout

Each module has `course.md` (landing page, ends with `<!-- astrona:playground -->`), `course-0N-*.md` parts, `course-0N-summary.md` (`# Summary`, last line `<!-- astrona:playground:destroy -->`), `playground/` (ungraded) and `labs/lab-01/` (graded). Each section has `capstone/labs/lab-01/`, `quiz.yaml` (`type: quiz`, pass_score 70) and `README.md`. `sections/final-domain-quiz.yaml` is the final quiz. Never list `solution.md` or playgrounds in `astrona.yaml`.

## Sections, labs and playgrounds

| Section | Module 1 (playground / lab) | Module 2 (playground / lab) | Capstone lab |
| --- | --- | --- | --- |
| 010 Applying Policy in Cluster | ats-010-playground-010-01 / ats-010-lab-001 | ats-010-playground-010-02 / ats-010-lab-002 | ats-010-lab-003 |
| 020 Resource Selection | ats-010-playground-020-01 / ats-010-lab-004 | ats-010-playground-020-02 / ats-010-lab-005 | ats-010-lab-006 |
| 030 Common Policy Settings | ats-010-playground-030-01 / ats-010-lab-007 | ats-010-playground-030-02 / ats-010-lab-008 | ats-010-lab-009 |
| 040 Applying Policy Types | ats-010-playground-040-01 / ats-010-lab-010 | ats-010-playground-040-02 / ats-010-lab-011 | ats-010-lab-012 |
| 050 Policy Reports & Results | ats-010-playground-050-01 / ats-010-lab-013 | ats-010-playground-050-02 / ats-010-lab-014 | ats-010-lab-015 |
| 060 Kyverno CLI: apply & test | ats-010-playground-060-01 / ats-010-lab-016 | ats-010-playground-060-02 / ats-010-lab-017 | ats-010-lab-018 |

## Manifest tags

Lab entries in `astrona.yaml` carry `difficulty`, `estimated_duration`, `topic`, `task_kind` (`build`, `troubleshooting` or `migration`), `tags` and `learning_goals`.

## Rules

- Static checks only: `astrona validate -c <dir>`, `bash -n`, `ruby -ryaml`. Do not boot labs unless asked.
- Kyverno resource selection uses `selector` inside `match`/`exclude` (there is no `objectSelector` field).
- Validation scripts are idempotent, print `PASS:` or `FAIL:` and poll with timeouts for asynchronous results.
- Follow the writing style of ATS021/CLAUDE.md: plain technical English, no metaphors, no navigation lines between pages.
