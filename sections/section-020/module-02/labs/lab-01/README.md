---
estimated_duration: 25m
---

# Identity-Based Resource Selection Lab

> UNTESTED - built from static checks only; not yet booted.

Graded lab for Module 2 of Section 020. You combine `selector`, `operations`, and a `subjects`-based `exclude` block to build a rule that applies to exactly one label-selected slice of Pods, except for one trusted automation identity. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-010-lab-005
```

Authors run the local copy with `astrona run -c <lab>` and would prove the reference solution with `astrona test -c <lab>` once the lab has been booted for the first time.

## Checks

The checks use server-side dry-run probes with unique names, so they leave no objects behind. They poll for up to about a minute while Kyverno loads the policy.

| Script | What it proves |
| --- | --- |
| `validate-policy-defined.sh` | The policy exists, is `Enforce`, uses `selector`, `operations: [CREATE]`, a `ci-deployer` exclude and `background: false` |
| `validate-frontend-blocked.sh` | A `tier=frontend` Pod with image `nginx` is rejected; `registry.internal/nginx` is admitted |
| `validate-ci-deployer-excluded.sh` | The same Pod is admitted when requested as `ci-deployer` |
| `validate-out-of-scope-admitted.sh` | `tier=backend` Pods and an `UPDATE` relabel are admitted |
| `validate-exercise-objects.sh` | `frontend-pod` is absent; `ci-pod` and `backend-pod` exist |
