---
estimated_duration: 25m
---

# Lab: generateExisting & applyRules

> UNTESTED - built from static checks only; not yet booted.

Graded lab for Module 2. Backfill a default-deny `NetworkPolicy` into namespaces that existed before the policy, then use `applyRules: "One"` to give every namespace exactly one cost-center label. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-010-lab-008
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-generateexisting-backfill.sh` | `generateExisting` is set; `default-deny-ingress` exists in `team-a/b/c` as a real default-deny, and not in system namespaces |
| `validate-forward-generation.sh` | `team-d`, created later, also got the NetworkPolicy |
| `validate-applyrules-one-policy.sh` | `label-namespace-by-tier` has `applyRules: One` and the rules in the required order |
| `validate-gold-tier-premium.sh` | `team-a` is `tier=gold` with `cost-center=premium` |
| `validate-standard-tier-default.sh` | `team-e` has no tier and `cost-center=standard` |
