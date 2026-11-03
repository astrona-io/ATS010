---
estimated_duration: 30m
---

# Lab: Policy Reports and Results Capstone

UNTESTED - built from static checks only; not yet booted.

Capstone for Section 050. Two `Audit` policies, one for namespaced ConfigMaps and one for cluster-scoped Namespaces, have produced a `PolicyReport` in each of two namespaces and a `ClusterPolicyReport`. The learner reads all of them, records the findings, remediates every violator, waits for both report kinds to turn clean, flips both policies to `Enforce` and proves the rejections. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-010-lab-015
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine running the checks needs `kubectl` and `jq`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-findings-recorded.sh` | `capstone-findings` lists `fleet-a/a-bad,fleet-b/b-bad,fleet-b/b-stale` and `fleet-b` |
| `validate-violators-remediated.sh` | `a-bad` and `b-bad` have an `owner` label, `b-stale` is deleted, `fleet-b` has a `team` label, the compliant objects remain |
| `validate-reports-clean.sh` | Polls up to 300s: 0 `fail` and exactly 2 `pass` in each namespace report (none for `b-stale`), 0 `fail` and 2 `pass` in the `ClusterPolicyReport` |
| `validate-policies-enforce.sh` | Both policies have `validationFailureAction: Enforce` |
| `validate-enforcement-works.sh` | Server-side dry runs: a bad ConfigMap and a bad Namespace are rejected, good ones admitted (polled) |

The order "reports clean, then flip" is taught, not enforced by the checks. Open assumptions: the Namespace policy produces results in the `ClusterPolicyReport` for the labelled Namespaces, and a label update on a Namespace refreshes its result within the polling window.
