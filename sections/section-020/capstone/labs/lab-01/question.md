# Question

Solve this question on: `terminal`

The namespaces `store-prod` (labeled `env: prod`) and `store-dev` (labeled `env: dev`) already exist, plus a ServiceAccount `release-bot` in `store-prod` (already granted RBAC to create/update Deployments there).

1.  Write a `ClusterPolicy` named `require-approved-release` with a validate rule that:
    - Matches `kinds: [Deployment]`, `names: ["release-*"]`, `namespaceSelector.matchLabels: {env: prod}`, `objectSelector.matchLabels: {channel: stable}`, `operations: [CREATE, UPDATE]`.
    - Excludes requests from the `release-bot` ServiceAccount in `store-prod` via `subjects`.
    - Requires `metadata.annotations["approved-by"]` to be present and non-empty.
    - Uses `validationFailureAction: Enforce`.
2.  Apply the policy.
3.  Using your normal (default) identity, attempt to create a Deployment named `release-app` in `store-prod` labeled `channel: stable` with no `approved-by` annotation. Confirm it is rejected.
4.  Impersonating the `release-bot` ServiceAccount (`kubectl --as=system:serviceaccount:store-prod:release-bot`), create that same Deployment (`release-app`, `channel: stable`, no annotation) in `store-prod`. Confirm it is admitted.
5.  Using your normal identity, create a Deployment named `release-canary` in `store-prod` labeled `channel: beta` (not `stable`) with no `approved-by` annotation. Confirm it is admitted (out of scope: `objectSelector` requires `channel: stable`).
6.  Using your normal identity, create a Deployment named `release-app` in `store-dev` labeled `channel: stable` with no `approved-by` annotation. Confirm it is admitted (out of scope: `store-dev` is not selected by the `env: prod` namespaceSelector).
