---
estimated_duration: 40m
---

# Capstone Lab: Onboard A Namespace With Policies

UNTESTED - built from static checks only; not yet booted.

Capstone for the policy types section. The cluster starts with Kyverno 1.13.2 and a labelled namespace `shipyard`. You combine RBAC for Kyverno, a generate policy, a mutate policy, a validate policy and a cleanup policy. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-010-lab-012
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policies-ready.sh` | Three ClusterPolicies are `Ready` and the cleanup policy exists |
| `validate-controller-rbac.sh` | `can-i` answers `yes` for the background controller (NetworkPolicies, ResourceQuotas) and the cleanup controller (delete ConfigMaps) |
| `validate-onboarding-generate.sh` | A new labelled namespace gets `team-quota` (pods 15) and `default-deny-ingress`; an edited quota is restored; an unlabelled namespace gets nothing |
| `validate-pod-mutation.sh` | A pod in `shipyard` gets `cost-center=shared`, an explicit value is kept, a pod in `default` is untouched |
| `validate-pod-guardrails.sh` | `workload-guardrails` is `Enforce`, rejects `hostNetwork: true`, and still admits a label-less pod |
| `validate-expire-cleanup.sh` | The cleanup policy deletes a `ttl-expired=true` ConfigMap in `shipyard` and keeps the others |

Every check creates its own throwaway objects (named `cap-check-*` and `chk-*`) and removes them, so all checks are repeatable. The cleanup check can take up to four minutes.
