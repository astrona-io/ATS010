---
estimated_duration: 20m
---

# Lab: Enforce-Mode Resource Limits Policy

> UNTESTED - built from static checks only; not yet booted.

Graded lab for the "Getting a Policy Live" module. The cluster starts with Kyverno v1.13.2, its webhooks ready, and an empty namespace `platform-ns`. You apply a policy in `Audit` mode, watch it admit and report a violation, switch it to `Enforce`, and prove it now blocks new violators. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-010-lab-001
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policy-ready-and-enforce.sh` | `require-resource-limits` is Ready, matches Pod in `platform-ns` and ends in `Enforce` |
| `validate-audit-era-pod-reported.sh` | `no-limits-pod` exists and a `PolicyReport` has a failing result for it |
| `validate-enforce-blocks-violator.sh` | A Pod without limits is rejected (server-side dry run) and `no-limits-pod-2` does not exist |
| `validate-compliant-pod-admitted.sh` | `has-limits-pod` has both limits and a compliant Pod is still accepted |

The scripts only use `kubectl get` and `--dry-run=server`, so they can run repeatedly without changing the cluster. `jq` is required.
