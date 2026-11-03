# Overview: Rule-Level Settings (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno v1.13.2 and a few objects that already exist, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno v1.13.2 in the `kyverno` namespace, all four controllers ready.
- Namespaces `team-a`, `team-b` and `team-c`, created before any policy.
- A Deployment `web` (nginx) in `team-a` and in `team-b`, with no labels beyond the default `app=web`.
- A ClusterRole `ats010-background-controller-extra`, aggregated into Kyverno's background controller. Generate and mutate-existing rules run in that controller, so it needs rights on NetworkPolicies, ConfigMaps and Deployments. Without such a rule a backfill silently produces nothing.
- No `ClusterPolicy` and no `Policy`.

## Helpers

```sh
# Which namespaces got the generated NetworkPolicy?
netpols() { kubectl get networkpolicy -A --field-selector metadata.name=default-deny-ingress; }
# Cost-center and tier labels of every namespace
ns_labels() { kubectl get ns -L tier,cost-center; }
# Labels on the web Deployments
web_labels() { kubectl get deploy web -A --show-labels; }
```

## Practice tasks

- Apply a `generate` policy that creates a default-deny `NetworkPolicy` in every namespace, without `generateExisting`. Run `netpols`: which namespaces got it? Create `team-d` and run it again. Then set `generateExisting: true`, re-apply, and compare.
- Delete the generated `NetworkPolicy` in `team-a` by hand. With `synchronize: true` on the rule, what do you expect to see a moment later? Try it, then try again with `synchronize: false`.
- Write a policy with `applyRules: "One"` and two mutate rules (gold-tier override first, standard default second). Label `team-a` with `tier=gold`, create `team-e` with no label, and check `ns_labels`. Then swap the rule order and repeat on a fresh namespace.
- Remove `applyRules` (so it is `All`) and see which label wins when both rules match. Predict first.
- Write a mutate rule with a `targets` block for Deployments and `mutateExistingOnPolicyUpdate: true`. Run `web_labels` right after applying. Change the label value in the policy and run it again.
- Delete the extra ClusterRole `ats010-background-controller-extra` and repeat the previous task. Look at `kubectl -n kyverno logs deploy/kyverno-background-controller --tail=50` for what the controller complains about, then restore the role.
