# Question

Solve this question on: `terminal`

1.  Write a `ClusterPolicy` named `require-resource-limits` with a validate rule that requires every container of every Pod in the `platform-ns` namespace to set `resources.limits.cpu` and `resources.limits.memory`. Set `validationFailureAction: Audit`.
2.  Apply the policy and confirm it exists and is ready.
3.  Create a Pod named `no-limits-pod` in `platform-ns` with no resource limits set. Confirm it is admitted (Audit does not block), and confirm it shows up as a violation in `kubectl get policyreport -n platform-ns`.
4.  Edit the policy to set `validationFailureAction: Enforce` and re-apply it.
5.  Attempt to create a second Pod named `no-limits-pod-2` in `platform-ns` with no resource limits. Confirm the API server now rejects it.
6.  Create a Pod named `has-limits-pod` in `platform-ns` that sets both `cpu` and `memory` limits on its container, and confirm it is admitted successfully.
