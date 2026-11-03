# Question

Solve this question on: `terminal`

Kyverno 1.13.2 is installed. The namespace `starfleet` exists and holds two ConfigMaps, `fleet-registry` (labelled `protected=true`) and `scratch-notes`. No policy exists. Create three ClusterPolicies. Every rule must match only the `starfleet` namespace, and every policy that matches `Pod` must carry the annotation `pod-policies.kyverno.io/autogen-controllers: none` so Kyverno does not generate extra rules for pod controllers.

1. Create a `ClusterPolicy` named `pod-defaults` with two `mutate` rules. The first rule uses `patchStrategicMerge`: every pod gets the label `team: platform` when it has no `team` label, and every container gets `securityContext.allowPrivilegeEscalation: false` when the author did not set that field. Values that the author sets must stay. The second rule uses `patchesJson6902` and sets `/spec/automountServiceAccountToken` to `false`.

2. Create a `ClusterPolicy` named `require-pod-standards` with `validationFailureAction: Enforce` and two `validate` rules. The first rule uses a `pattern` that requires a non-empty `team` label on every pod. The second rule uses a `pattern` that rejects any container image that ends with `:latest`. A pod without a `team` label must still be admitted, because the mutate rule adds the label first.

3. Create a `ClusterPolicy` named `protect-registry` with `validationFailureAction: Enforce` and `background: false`. A `deny` rule must block `DELETE` requests for any ConfigMap in `starfleet` that has the label `protected=true`. Other ConfigMaps must stay deletable.

Test your work with `kubectl`: read stored pods with `kubectl get pod -o yaml` and test deletes with `kubectl delete --dry-run=server`. Use the image `registry.k8s.io/pause:3.9` for test pods. `kubectl` already points at the cluster as the cluster administrator.
