# Question

Solve this question on: `terminal`

The namespaces `shop-prod` (labeled `env: prod`) and `shop-dev` (labeled `env: dev`) already exist.

1.  Write a `ClusterPolicy` named `require-reviewed-public-ingress` with a validate rule matching `kinds: [Ingress]`, `names: ["public-*"]`, and a `namespaceSelector` matching `matchLabels: {env: prod}`. Require `metadata.annotations["security-reviewed"]` to be present and non-empty. Use `validationFailureAction: Enforce`.
2.  Apply the policy.
3.  In `shop-prod`, attempt to create an Ingress named `public-shop` with no `security-reviewed` annotation. Confirm the API server rejects it.
4.  In `shop-prod`, create an Ingress named `internal-shop` (it does not match the `public-*` name filter) with no annotation. Confirm it is admitted.
5.  In `shop-dev`, create an Ingress named `public-shop` with no annotation. Confirm it is admitted (`shop-dev` is not selected by the `env: prod` namespaceSelector).
6.  In `shop-prod`, create an Ingress named `public-reviewed` with the annotation `security-reviewed: "true"`. Confirm it is admitted.
