# Question

Solve this question on: `terminal`

You run the shop platform. Public-facing Ingresses in production must carry a review annotation, but nothing else should be affected. Kyverno v1.13.2 is installed. The namespaces `shop-prod` (labeled `env: prod`) and `shop-dev` (labeled `env: dev`) already exist, and no policy exists yet.

1.  Write a `ClusterPolicy` named `require-reviewed-public-ingress` with a validate rule matching `kinds: [Ingress]`, `names: ["public-*"]`, and a `namespaceSelector` matching `matchLabels: {env: prod}`. Require `metadata.annotations["security-reviewed"]` to be present and non-empty. Use `validationFailureAction: Enforce`.
2.  Apply the policy.
3.  In `shop-prod`, attempt to create an Ingress named `public-shop` with no `security-reviewed` annotation. Confirm the API server rejects it.
4.  In `shop-prod`, create an Ingress named `internal-shop` (it does not match the `public-*` name filter) with no annotation. Confirm it is admitted.
5.  In `shop-dev`, create an Ingress named `public-shop` with no annotation. Confirm it is admitted (`shop-dev` is not selected by the `env: prod` namespaceSelector).
6.  In `shop-prod`, create an Ingress named `public-reviewed` with the annotation `security-reviewed: "true"`. Confirm it is admitted.
7.  The policy must follow namespace labels, not a fixed list: the grader will create a new namespace labeled `env: prod` and expect `public-*` Ingresses there to be rejected too. Do not name `shop-prod` anywhere in the policy.

Notes:

- An Ingress needs no running controller or backend Service to be created; a `defaultBackend` or one simple rule is enough.
- Use `kubectl apply --dry-run=server -f <file>` whenever you want to ask Kyverno a question without creating anything.
- After applying the policy, allow a few seconds before the first rejection appears.
