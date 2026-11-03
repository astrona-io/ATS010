---
estimated_duration: 30m
---

# Lab: Apply Generate And Cleanup Policies

UNTESTED - built from static checks only; not yet booted.

Graded lab for the generate and cleanup module. The cluster starts with Kyverno 1.13.2, a clone source in `fleet-system` and two labelled ConfigMaps in `scratch`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-010-lab-011
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policies-ready.sh` | `namespace-defaults` is `Ready` and `remove-expired-configmaps` exists |
| `validate-controller-rbac.sh` | `can-i` answers `yes` for the background controller (create networkpolicies, resourcequotas, configmaps) and the cleanup controller (delete configmaps) |
| `validate-generate-on-create.sh` | A new labelled namespace gets the quota, the NetworkPolicy and the clone; an unlabelled one gets nothing |
| `validate-synchronize-behaviour.sh` | `synchronize` values in the policy, plus a deleted NetworkPolicy returns, an edited quota is restored, an edited clone keeps its edit |
| `validate-cleanup-expired.sh` | The schedule is at most two minutes; a ConfigMap labelled `expired=true` is deleted, `expired=false` ones are kept |

Every check creates its own throwaway namespaces or ConfigMaps (named `lab-check-*` and `chk-*`) and removes them, so all checks are repeatable. The cleanup check can take up to four minutes.
