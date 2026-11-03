---
estimated_duration: 30m
---

# Common Policy Settings Integration Capstone

> UNTESTED - built from static checks only; not yet booted.

Welcome to the Section 030 Capstone. This challenge combines webhook resilience settings, retroactive generation into a pre-existing namespace, and priority-ordered mutate rules into one integrated task, mirroring the kind of layered, production-grade policy set a real platform team maintains. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-010-lab-009
```

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limits-policy-enforces.sh` | `ops-require-limits` has Fail, 8 seconds, Enforce, background true, rejects a Pod without limits, and `has-limits-pod` exists |
| `validate-audit-configmap-backfill.sh` | `audit-config` was generated into `ops-prod` and the pre-existing `ops-legacy`, not into system namespaces |
| `validate-tier-cost-labels.sh` | `tier-cost-labels` uses `applyRules: One`, gold rule first, and `ops-prod` has `cost-center=premium` |
