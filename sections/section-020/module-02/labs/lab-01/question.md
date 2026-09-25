# Question

Solve this question on: `terminal`

The namespace `apps-ns` and a ServiceAccount `ci-deployer` (already granted RBAC to create Pods in `apps-ns`) already exist.

1.  Write a `ClusterPolicy` named `restrict-frontend-images` with a validate rule that:
    - Matches `kinds: [Pod]`, `namespaces: [apps-ns]`, `objectSelector.matchLabels: {tier: frontend}`, `operations: [CREATE]`.
    - Excludes requests from the `ci-deployer` ServiceAccount in `apps-ns` via `subjects`.
    - Requires every container's `image` to match the pattern `"registry.internal/*"`.
    - Uses `validationFailureAction: Enforce`.
2.  Apply the policy.
3.  Using your normal (default) identity, attempt to create a Pod named `frontend-pod` in `apps-ns` with the label `tier=frontend` and image `nginx`. Confirm it is rejected.
4.  Impersonating the `ci-deployer` ServiceAccount (`kubectl --as=system:serviceaccount:apps-ns:ci-deployer`), create a Pod named `ci-pod` in `apps-ns` with the label `tier=frontend` and image `nginx`. Confirm it is admitted despite the same disallowed image.
5.  Using your normal identity, create a Pod named `backend-pod` in `apps-ns` with the label `tier=backend` and image `nginx`. Confirm it is admitted (it is not selected by the `tier: frontend` objectSelector).
