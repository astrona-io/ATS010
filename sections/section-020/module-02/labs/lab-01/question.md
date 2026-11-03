# Question

Solve this question on: `terminal`

Kyverno v1.13.2 is installed. The namespace `apps-ns` and a ServiceAccount `ci-deployer` (already granted RBAC to create Pods in `apps-ns`) already exist. No policy exists yet.

1.  Write a `ClusterPolicy` named `restrict-frontend-images` with a validate rule that:
    - Matches `kinds: [Pod]`, `namespaces: [apps-ns]`, `selector.matchLabels: {tier: frontend}`, `operations: [CREATE]`.
    - Excludes requests from the `ci-deployer` ServiceAccount in `apps-ns` via `subjects`.
    - Requires every container's `image` to match the pattern `"registry.internal/*"`.
    - Uses `validationFailureAction: Enforce` and `background: false` (a policy that selects by requester identity only makes sense on admission requests).
2.  Apply the policy.
3.  Using your normal (default) identity, attempt to create a Pod named `frontend-pod` in `apps-ns` with the label `tier=frontend` and image `nginx`. Confirm it is rejected.
4.  Impersonating the `ci-deployer` ServiceAccount (`kubectl --as=system:serviceaccount:apps-ns:ci-deployer`), create a Pod named `ci-pod` in `apps-ns` with the label `tier=frontend` and image `nginx`. Confirm it is admitted despite the same disallowed image.
5.  Using your normal identity, create a Pod named `backend-pod` in `apps-ns` with the label `tier=backend` and image `nginx`. Confirm it is admitted (it is not selected by the `tier: frontend` selector).
6.  Without changing anything, ask the API server whether relabeling `backend-pod` into the frontend scope would be allowed: `kubectl label pod backend-pod tier=frontend --overwrite -n apps-ns --dry-run=server`. Confirm it is admitted, because the rule only evaluates `CREATE`.

Notes:

- The field that selects by the Pod's own labels is called `selector` in a Kyverno policy.
- Allow a few seconds after applying the policy before the first rejection appears.
