---
estimated_duration: 20m
---

# Lab: failurePolicy & webhookTimeoutSeconds

> UNTESTED - built from static checks only; not yet booted.

Graded lab for Module 1. Write two `ClusterPolicy` resources with opposite `failurePolicy` settings, prove they enforce the same rule while Kyverno is healthy, and leave the admission controller healthy. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-010-lab-007
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-strict-policy-settings.sh` | `require-app-label-strict` is Ready with Fail, 5 seconds and Enforce |
| `validate-lenient-policy-settings.sh` | `require-app-label-lenient` is Ready with Ignore, 5 seconds and Enforce |
| `validate-critical-ns-enforces-label.sh` | An unlabelled Pod is denied in `critical-ns` (server dry run); `has-app-pod` exists, `no-app-pod` does not |
| `validate-lenient-ns-enforces-label.sh` | The same for `lenient-ns` |
| `validate-admission-controller-healthy.sh` | The admission controller has all replicas ready |
