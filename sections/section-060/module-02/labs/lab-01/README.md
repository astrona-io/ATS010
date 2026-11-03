---
estimated_duration: 30m
---

# Lab: Write And Run Policy Tests With kyverno test

> **UNTESTED - built from static checks only; not yet booted.**

Graded lab for Module 2. You write two `kyverno-test.yaml` files, an expected mutated Pod and a CI script in `$HOME/kyverno-lab/m2`. The validation scripts run `kyverno test` themselves, also on a copy with a broken policy. The last check is on the cluster. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-02/labs/lab-01
astrona destroy ats-010-lab-017
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-limits-test.sh` | `tests/limits/kyverno-test.yaml` has pass and fail results for `check-limits`, and `kyverno test` succeeds |
| `validate-mutate-test.sh` | `tests/labels` uses `patchedResources` with an expected Pod, and `kyverno test` succeeds |
| `validate-regression-caught.sh` | `kyverno test` fails on a copy where `require-limits` is broken |
| `validate-ci-script.sh` | `ci/run-policy-tests.sh` is executable, stops on errors, runs `kyverno test` and works from any directory |
| `validate-policy-live.sh` | `require-limits` is Ready in the cluster, rejects `web-nolimits`, admits `web-ok` |
