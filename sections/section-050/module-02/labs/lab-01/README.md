---
estimated_duration: 25m
---

# Lab: Use Reports as a Rollout Gate

UNTESTED - built from static checks only; not yet booted.

Graded lab for the report-lifecycle module. `rollout-lab` has one compliant and three non-compliant ConfigMaps under an `Audit` policy. The learner reads the reports, fixes or deletes the violators, waits for the reports to turn clean, flips the policy to `Enforce`, and proves the rejection. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-010-lab-014
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine running the checks needs `kubectl` and `jq`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-violators-remediated.sh` | `bad-1` and `bad-2` have an `owner` label, `bad-3` is deleted, `ok-1` remains |
| `validate-reports-clean.sh` | Polls up to 300s: 0 `fail`, exactly 3 `pass` and no result for `bad-3` in the `require-owner-label` reports of `rollout-lab` |
| `validate-policy-enforce.sh` | `validationFailureAction` is `Enforce` and the policy still has a validate rule |
| `validate-enforcement-works.sh` | Server-side dry runs: a violator is rejected (message names the policy), a compliant ConfigMap is admitted (polled up to 120s and 60s) |
| `validate-gate-record.sh` | `gate-record` holds `violators-found=3` and `fail-at-flip=0` |

The order "reports clean, then flip" is taught, not enforced by the checks; the checks cannot see the order of events. Open assumptions: a label update on a ConfigMap refreshes its result in the reports within the polling window, and deleting a ConfigMap removes its result.
