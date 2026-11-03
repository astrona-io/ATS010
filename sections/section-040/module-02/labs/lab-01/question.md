# Question

Solve this question on: `terminal`

Kyverno 1.13.2 is installed. The namespace `fleet-system` holds the ConfigMap `fleet-banner`. The namespace `scratch` holds the ConfigMaps `old-report` (label `expired: "true"`) and `keep-report` (label `expired: "false"`). No policy exists, and no extra RBAC has been added for Kyverno.

1. Create a `ClusterPolicy` named `namespace-defaults`. For every **new** `Namespace` that carries the label `fleet-managed: "true"` it must generate three resources in that namespace, each from its own rule:
   - rule `default-quota`: a `ResourceQuota` named `default-quota` that limits `pods` to `"10"`, from inline `data`, with `synchronize: true`.
   - rule `default-deny-ingress`: a `NetworkPolicy` named `default-deny-ingress` that selects all pods (`podSelector: {}`), has `policyTypes: [Ingress]` and no `ingress` rules, from inline `data`, with `synchronize: true`.
   - rule `clone-banner`: a `ConfigMap` named `fleet-banner` cloned from `fleet-system/fleet-banner`, with `synchronize: false`.

2. Give Kyverno the permissions that these rules need. Check what the service accounts `kyverno-background-controller` and `kyverno-cleanup-controller` in the namespace `kyverno` may do with `kubectl auth can-i --as=system:serviceaccount:kyverno:<name>`. The background controller must be able to create `networkpolicies`, `resourcequotas` and `configmaps`. The cleanup controller must be able to delete `configmaps`. Add ClusterRoles with the Kyverno aggregation labels for this. Do not edit Kyverno's own ClusterRoles.

3. Create a `ClusterCleanupPolicy` named `remove-expired-configmaps` that deletes every ConfigMap in the namespace `scratch` whose label `expired` is `"true"`. ConfigMaps with another value, or without the label, must stay. It must run every minute (`"* * * * *"`). Use `apiVersion: kyverno.io/v2`.

Do not delete `keep-report`. The grader creates its own test namespaces and ConfigMaps, so it needs no particular objects from you. `kubectl` already points at the cluster as the cluster administrator.
