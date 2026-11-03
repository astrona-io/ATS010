# Overview: match/exclude Fundamentals (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno and a few namespaces, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Kyverno v1.13.2** with its admission, background, cleanup and reports controllers ready. No `ClusterPolicy` or `Policy` exists yet.

  | Namespace | Labels | Contents |
  | --- | --- | --- |
  | `shop-prod` | `env=prod` | ConfigMaps `app-secrets`, `db-secrets`, `credentials`, `prod-settings`, `canary-settings` |
  | `shop-dev` | `env=dev` | ConfigMap `app-settings` |
  | `shop-stage` | `env=staging` | Empty |

## Helpers

Paste these once in each new terminal. `probe_cm` asks the API server (and so Kyverno) about a ConfigMap without creating it. `probe_ingress` does the same for an Ingress. Both use server-side dry-run: the whole admission chain runs, nothing is stored. A rejection names the policy that blocked it.

```sh
probe_cm() {
  kubectl create configmap "$1" -n "$2" --from-literal=k=v --dry-run=server -o name
}
probe_ingress() {
  cat <<YAML | kubectl create --dry-run=server -f - -o name
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: $1, namespace: $2}
spec:
  defaultBackend: {service: {name: svc, port: {number: 80}}}
YAML
}
```

Use them like this: `probe_cm cache-secrets shop-prod`, `probe_ingress public-x shop-dev`.

## Practice tasks

- Write an Enforce rule that requires a `classified` label on ConfigMaps named `*-secrets` in `shop-prod`. Predict, then probe: `db-secrets`, `secrets-db`, `credentials`, `app-secrets-v2`. Which one is the "naming is not security" gap?
- Change `names` to `["?b-*"]` and predict which ConfigMap names still match (`?` is exactly one character).
- Rewrite the rule to scope by `namespaceSelector: {matchLabels: {env: prod}}` instead of `namespaces`. Probe the same name in `shop-stage`, then run `kubectl label ns shop-stage env=prod --overwrite` and probe again. Restore the label afterwards.
- Use `matchExpressions` with `operator: In` and `values: [prod, staging]` in `namespaceSelector` and check which namespaces are now in scope.
- Add an `exclude` for names `canary-*`. Then deliberately add `namespaces: [shop-prod]` into the same exclude block and think about what is now excluded (the AND trap).
- Write a rule for `kinds: [Pod/exec]` with `operations: [CONNECT]` and a `deny` condition, start a Pod in `shop-dev` with `kubectl run`, run `kubectl exec` into it, and compare with a rule on plain `Pod`.
- Create a namespaced `Policy` in `shop-dev` that matches ConfigMaps and probe `shop-prod`: it must not apply there.
