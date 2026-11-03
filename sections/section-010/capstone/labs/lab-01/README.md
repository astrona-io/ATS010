---
estimated_duration: 30m
---

# Lab: Applying Policy in Cluster Integration Capstone

> UNTESTED - built from static checks only; not yet booted.

Capstone for the "Applying Policy in Cluster" section. It combines `Enforce`, `Audit`, background scanning, autogen and a PolicyException in one task, the way a platform team rolls policy out namespace by namespace. The cluster starts with Kyverno v1.13.2, the namespaces `checkout-live` and `reporting-live`, and a running `old-reporter` Deployment without limits. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-010-lab-003
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-checkout-enforces-limits.sh` | `checkout-require-limits` is Ready, uses `Enforce` and rejects a Pod without limits in `checkout-live` (dry run); `no-limits-checkout` does not exist |
| `validate-reporting-audits-limits.sh` | `reporting-audit-limits` is Ready, uses `Audit` and admits a Pod without limits in `reporting-live`; `no-limits-reporting` exists |
| `validate-old-reporter-untouched-and-reported.sh` | `old-reporter` is ready with no limits and a `PolicyReport` exists in `reporting-live` |
| `validate-policyexceptions-enabled.sh` | The admission controller has both arguments (`checkout-live`) and its rollout is finished |
| `validate-migration-job-excepted.sh` | `allow-migration-job` names the Pod rule, a Job named like it is admitted without limits (so the autogen rule is covered), and `migration-job` created a Pod |

The scripts only read the cluster or use `--dry-run=server`, so they can run repeatedly. `jq` is required.
