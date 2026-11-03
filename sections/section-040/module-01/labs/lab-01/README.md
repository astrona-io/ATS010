---
estimated_duration: 25m
---

# Lab: Apply Mutate And Validate Policies

UNTESTED - built from static checks only; not yet booted.

Graded lab for the validate and mutate module. The cluster starts with Kyverno 1.13.2, a `starfleet` namespace and two ConfigMaps. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-010-lab-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policies-ready.sh` | The three ClusterPolicies exist and report `Ready` |
| `validate-mutate-defaults.sh` | `patchStrategicMerge` adds `team=platform` and `allowPrivilegeEscalation=false` to the stored pod and keeps explicit values |
| `validate-json6902-automount.sh` | A `patchesJson6902` rule sets `automountServiceAccountToken` to `false` |
| `validate-mutate-before-validate.sh` | `require-pod-standards` is `Enforce` with a team label pattern, and a label-less pod is still admitted |
| `validate-reject-latest-image.sh` | A `:latest` image is rejected by `require-pod-standards`; a pinned image is admitted |
| `validate-deny-delete-protected.sh` | `protect-registry` blocks deleting `fleet-registry` and still allows deleting `scratch-notes` (server-side dry run) |

Every check that creates pods retries for about a minute, because the Kyverno webhook can need a few seconds to pick up a new policy. All checks are repeatable.
