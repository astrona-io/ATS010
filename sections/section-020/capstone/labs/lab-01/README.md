---
estimated_duration: 30m
---

# Resource Selection Integration Capstone

> UNTESTED - built from static checks only; not yet booted.

Capstone for Section 020. You combine every selection axis from the section (name wildcards, `namespaceSelector`, `selector`, `operations` and a `subjects`-based exclude) into a single policy, mirroring the layered, precisely-scoped guardrail a real platform team maintains. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-010-lab-006
```

Authors run the local copy with `astrona run -c <lab>` and would prove the reference solution with `astrona test -c <lab>` once the lab has been booted for the first time.

## Checks

The checks use server-side dry-run probes with unique names, so they leave no objects behind. They poll for up to about a minute while Kyverno loads the policy.

| Script | What it proves |
| --- | --- |
| `validate-policy-defined.sh` | The policy exists, is `Enforce`, uses all selection axes and `background: false` |
| `validate-in-scope-enforced.sh` | A stable `release-*` Deployment in `store-prod` is rejected without `approved-by`, admitted with it |
| `validate-each-axis-narrows.sh` | A different name, a `store-dev` namespace, or `channel=beta` each take a request out of scope |
| `validate-exclude-and-operations.sh` | `release-bot` is excluded and an `UPDATE` relabel is rejected (UPDATE in scope) |
| `validate-exercise-objects.sh` | `release-app` (both namespaces) and `release-canary` exist as the question requires |
