---
estimated_duration: 30m
---

# Lab: Background Scan & PolicyException

> UNTESTED - built from static checks only; not yet booted.

Graded lab for the "Applying Beyond Admission" module. The cluster starts with Kyverno v1.13.2, its webhooks ready, and a running Deployment `legacy-worker` without resource limits in `background-ns`. You apply an `Enforce` policy, observe autogen and the background scan, enable PolicyExceptions and use one to let `legacy-worker` roll a new Pod. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-010-lab-002
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policy-live-with-autogen.sh` | `require-resource-limits-bg` is Ready, uses `Enforce`, has `background` on and has autogen rules (not disabled) |
| `validate-background-scan-reported.sh` | A `PolicyReport` exists in `background-ns` and `legacy-worker` still has no limits and was not removed |
| `validate-new-worker-blocked.sh` | A Deployment without limits is rejected (server-side dry run) and `new-worker` does not exist |
| `validate-policyexceptions-enabled.sh` | The admission controller has both arguments and its rollout is finished |
| `validate-exception-admits-legacy-worker.sh` | `allow-legacy-worker` names the Pod rule, a Deployment named `legacy-worker-grader` without limits is admitted (so the autogen rule is covered), and `legacy-worker` rolled a new ready Pod |

The scripts only read the cluster or use `--dry-run=server`, so they can run repeatedly. `jq` is required. The report check accepts any report in the namespace, because the results for `legacy-worker` can change after the exception exists.
