# Part 2 — generateExisting & mutateExistingOnPolicyUpdate

> Prerequisite: [Part 1 — applyRules: All vs One](./course-01-applyrules-all-vs-one.md). Next: [Section 030 Knowledge Check](../quiz.md).

## The default: generate and mutate only look forward

A `generate` rule fires when a matching **trigger** resource is admitted — a new `Namespace` being created, for example. That's the mechanism you used in Section 010 and in the Fundamentals of Kyverno domain to clone a `ConfigMap` or a default-deny `NetworkPolicy` into every namespace. But notice the phrasing: it fires on a trigger resource *being admitted*. By default, a `generate` rule has nothing to say about trigger resources that were already sitting in the cluster before the policy existed — they were admitted long before this policy's webhook was ever registered, so there was no admission event for the rule to react to.

The same forward-only default applies to `mutate` rules: they patch a resource as it is admitted (created or updated), not resources that already exist and simply aren't being touched right now.

## generateExisting: true — populate the backlog retroactively

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-default-netpol
spec:
  generateExisting: true
  rules:
    - name: clone-netpol-to-namespace
      match:
        any:
        - resources:
            kinds:
              - Namespace
      exclude:
        any:
        - resources:
            namespaces:
              - kube-system
              - kyverno
              - kube-node-lease
              - kube-public
              - local-path-storage
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
```

Setting `spec.generateExisting: true` on the policy tells Kyverno to also run this generate logic against trigger resources that already existed at the moment the policy was created or updated — not just resources created afterward. Applying the policy above with `generateExisting: true` immediately backfills the default-deny `NetworkPolicy` into every namespace that was already there, in addition to every namespace created from that point on.

This matters most exactly when you'd expect: rolling out a new cluster-wide guardrail onto a cluster that already has dozens of namespaces. Without `generateExisting: true`, the new policy would only ever apply to namespaces created after today, leaving every pre-existing namespace silently uncovered until someone notices and patches them by hand.

## mutateExistingOnPolicyUpdate — the same idea, for mutate

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: relabel-existing-deployments
spec:
  mutateExistingOnPolicyUpdate: true
  rules:
    - name: add-managed-by-label
      match:
        any:
        - resources:
            kinds:
              - Deployment
      mutate:
        targets:
          - apiVersion: apps/v1
            kind: Deployment
            namespace: "*"
        patchStrategicMerge:
          metadata:
            labels:
              managed-by: platform-team
```

A normal `mutate` rule only ever patches the resource that triggered admission — the one being created or updated right now. A `mutate` rule that instead uses a `targets` block (naming a different kind/scope of resource to patch, as shown above) combined with the policy-level `mutateExistingOnPolicyUpdate: true` setting tells Kyverno: whenever this policy itself is created or updated, go find every resource matching `targets` right now, in the cluster's current state, and patch it too — not just resources admitted going forward.

This is the `mutate` equivalent of `generateExisting`: instead of only fixing up what happens next, it reaches back and repairs the resources that are already there, at the moment you roll the policy out (or change it).

> [!TIP]
> **Conceptual walkthrough — exploratory, not part of this lab's graded task**
>
> Imagine a cluster with fifty existing Deployments, none carrying a `managed-by` label. You write the policy above with `mutateExistingOnPolicyUpdate: true` and a `targets` block matching `apps/v1, Deployment` in every namespace. The moment you `kubectl apply` it, Kyverno doesn't wait for someone to touch those fifty Deployments — it walks the existing set matching `targets` and patches them immediately. Editing the policy later (say, changing the label value) triggers the same retroactive sweep again, since it fires "on policy update," not just "on policy create."

> [!WARNING]
> **Common pitfall**
>
> `generateExisting` and `mutateExistingOnPolicyUpdate` are two different fields for two different rule types — one only means something on `generate` rules, the other only means something on `mutate` rules using a `targets` block. Setting `generateExisting: true` on a policy that only has `mutate` rules (or vice versa) does nothing at all; there's no cross-wiring between the two mechanisms.

## Reference

- `kubectl explain clusterpolicy.spec.generateExisting`
- `kubectl explain clusterpolicy.spec.mutateExistingOnPolicyUpdate`
