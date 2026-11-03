---
estimated_duration: 20m
---

# Namespace & Kind Scoped Policy Lab

> UNTESTED - built from static checks only; not yet booted.

Graded lab for Module 1 of Section 020. You combine a name-wildcard filter with a dynamic `namespaceSelector` to scope a validate rule to exactly the resources it should, and nothing else. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-010-lab-004
```

Authors run the local copy with `astrona run -c <lab>` and would prove the reference solution with `astrona test -c <lab>` once the lab has been booted for the first time.

## Checks

The checks use server-side dry-run probes with unique names, so they leave no objects behind. They poll for up to about a minute while Kyverno loads the policy.

| Script | What it proves |
| --- | --- |
| `validate-policy-defined.sh` | The policy exists, is `Enforce`, and uses `Ingress`, `public-*` and a `namespaceSelector` |
| `validate-public-blocked-in-prod.sh` | An unannotated `public-*` Ingress in `shop-prod` is rejected by the policy |
| `validate-out-of-scope-admitted.sh` | `internal-*` in `shop-prod` and `public-*` in `shop-dev` are admitted |
| `validate-namespace-selector-is-dynamic.sh` | A new namespace labeled `env=prod` (created by the check) is covered too |
| `validate-reviewed-and-objects.sh` | A reviewed Ingress is admitted and the exercise objects exist |
