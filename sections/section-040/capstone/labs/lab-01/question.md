# Question

Solve this question on: `terminal`

The platform team onboards new teams into a shared cluster. Kyverno 1.13.2 is installed. The namespace `shipyard` already exists with the label `onboarding: "true"` and holds the ConfigMaps `shipyard-notes` and `shipyard-old` (label `ttl-expired: "true"`). No policy exists, and no extra RBAC has been added for Kyverno. Build the onboarding policies with all the policy types of this section.

1. **Permissions.** The Kyverno background controller must be able to create `networkpolicies` and `resourcequotas`, and the cleanup controller must be able to delete `configmaps`. Check with `kubectl auth can-i --as=system:serviceaccount:kyverno:<kyverno-background-controller or kyverno-cleanup-controller>`. Add ClusterRoles that carry the Kyverno aggregation labels. Do not edit Kyverno's own roles.

2. **Generate.** Create a `ClusterPolicy` named `onboard-namespace`. For every new `Namespace` with the label `onboarding: "true"` it generates, in two rules, a `ResourceQuota` named `team-quota` that limits `pods` to `"15"` and a `NetworkPolicy` named `default-deny-ingress` (`podSelector: {}`, `policyTypes: [Ingress]`, no ingress rules). Both use inline `data` and `synchronize: true`.

3. **Mutate.** Create a `ClusterPolicy` named `workload-defaults` with a `patchStrategicMerge` rule. Every pod in a namespace that has the label `onboarding: "true"` (use `namespaceSelector` in the `match` block) gets the label `cost-center: shared` when it has no `cost-center` label. An explicit value must stay. Pods in other namespaces, such as `default`, are not changed.

4. **Validate.** Create a `ClusterPolicy` named `workload-guardrails` with `validationFailureAction: Enforce` for pods in the same onboarding namespaces. One rule requires a non-empty `cost-center` label with a `pattern`. A second rule rejects pods that set `hostNetwork: true`. A pod with no `cost-center` label must still be admitted, because the mutate rule adds the label first.

5. **Cleanup.** Create a `ClusterCleanupPolicy` named `expire-shipyard-configmaps` (`apiVersion: kyverno.io/v2`) that runs every minute (`"* * * * *"`) and deletes the ConfigMaps in `shipyard` whose label `ttl-expired` is `"true"`. All other ConfigMaps in `shipyard` stay.

Every policy that matches `Pod` must carry the annotation `pod-policies.kyverno.io/autogen-controllers: none`. The grader creates its own test namespaces, pods and ConfigMaps. `shipyard` itself existed before your policies, so it gets no quota or NetworkPolicy; that is expected. `kubectl` already points at the cluster as the cluster administrator.
