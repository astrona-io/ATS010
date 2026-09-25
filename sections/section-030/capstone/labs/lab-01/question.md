# Question

Solve this question on: `terminal`

The namespace `ops-prod` already exists. The namespace `ops-legacy` also already exists, with a pre-existing Deployment named `legacy-svc` inside it (no resource limits set) — both created before you write any policy.

1.  Write a `ClusterPolicy` named `ops-require-limits` with a validate rule requiring every Pod in `ops-prod` to set CPU and memory `resources.limits`. Set `validationFailureAction: Enforce`, `failurePolicy: Fail`, `webhookTimeoutSeconds: 8`, and `background: true`.
2.  Apply it, then confirm a Pod with no resource limits is rejected in `ops-prod`, and a Pod named `has-limits-pod` with both CPU and memory limits set is admitted.
3.  Write a `ClusterPolicy` named `clone-audit-configmap` with a `generate` rule that clones an audit-logging `ConfigMap` named `audit-config` (with any non-empty `data` you choose) into every `Namespace`, excluding `kube-system`, `kyverno`, `kube-node-lease`, `kube-public`, and `local-path-storage`. Set `generateExisting: true` so the pre-existing `ops-legacy` namespace is also backfilled, not just `ops-prod`.
4.  Apply it, and confirm `audit-config` now exists in both `ops-prod` and `ops-legacy`.
5.  Write a `ClusterPolicy` named `tier-cost-labels` with `applyRules: "One"` and exactly two mutate rules, in this order: a `gold-tier-override` rule matching `Namespace` resources labeled `tier: gold` that patches in `cost-center: premium`, and a `standard-tier-default` catch-all rule matching all `Namespace` resources that patches in `cost-center: standard`.
6.  Apply it, then label `ops-prod` with `tier: gold` and confirm it ends up with `cost-center: premium` only (never also `standard`).
