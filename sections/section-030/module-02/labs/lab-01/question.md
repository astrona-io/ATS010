# Question

Solve this question on: `terminal`

The namespaces `team-a`, `team-b`, and `team-c` already exist, created before you write any policy.

1.  Write a `ClusterPolicy` named `clone-default-netpol` with a `generate` rule that clones a default-deny `NetworkPolicy` named `default-deny-ingress` (an empty `podSelector: {}` selecting all Pods, `policyTypes: [Ingress]`, no `ingress` rules) into every `Namespace`, excluding the `kube-system`, `kyverno`, `kube-node-lease`, `kube-public`, and `local-path-storage` namespaces. Set `generateExisting: true` at the policy level.
2.  Apply it, and confirm `default-deny-ingress` now exists in `team-a`, `team-b`, and `team-c` — created retroactively, since they existed before the policy did.
3.  Create a new namespace named `team-d`, and confirm it also receives `default-deny-ingress` (proving forward-going generation still works too).
4.  Write a second `ClusterPolicy` named `label-namespace-by-tier` with `applyRules: "One"` and exactly two mutate rules, in this order:
    *   Rule 1 (`gold-tier-override`): matches `Namespace` resources labeled `tier: gold`, and patches in the label `cost-center: premium`.
    *   Rule 2 (`standard-tier-default`): matches all `Namespace` resources with no further filter, and patches in the label `cost-center: standard`.
5.  Apply it. Label `team-a` with `tier: gold` (`kubectl label namespace team-a tier=gold`), and confirm it ends up with `cost-center: premium` — not `standard`.
6.  Create a new namespace named `team-e` with no `tier` label, and confirm it ends up with `cost-center: standard` from the catch-all rule.
