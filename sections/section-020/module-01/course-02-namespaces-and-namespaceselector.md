# Part 2 — Namespaces & namespaceSelector

> Prerequisite: [Part 1 — Selecting by Kind, Name & Wildcards](./course-01-selecting-by-kind-name-and-wildcards.md). Next: [Module 2 — Selecting by Identity & Operation](../module-02/course.md).

## `resources.namespaces` — a static list

The most direct way to scope a `ClusterPolicy` rule to particular namespaces is a literal list:

```yaml
match:
  any:
  - resources:
      kinds:
        - Ingress
      namespaces:
        - shop-prod
```

Like `names`, entries here are wildcard-capable (`"shop-*"` would match `shop-prod` and `shop-dev` alike). But the list itself is **static** — it names namespaces by their literal identifiers, written directly into the policy YAML. Add a new namespace tomorrow that should also be in scope, and the policy does nothing about it until someone edits the list.

## `namespaceSelector` — a dynamic, label-driven scope

`namespaceSelector` takes a different approach: instead of naming namespaces, it names a **label selector**, evaluated against the *Namespace object itself* — not the resource being matched, the `Namespace` resource that resource happens to live inside.

```yaml
match:
  any:
  - resources:
      kinds:
        - Ingress
      namespaceSelector:
        matchLabels:
          env: prod
```

This rule applies to an `Ingress` in *any* namespace, as long as that namespace currently carries the label `env: prod`. `namespaceSelector` supports the full Kubernetes label selector grammar — `matchLabels` for exact key/value equality, and `matchExpressions` for `In`/`NotIn`/`Exists`/`DoesNotExist` operators.

## Static vs dynamic: why it matters

| | `resources.namespaces` | `namespaceSelector` |
| --- | --- | --- |
| What it reads | A literal list in the policy YAML | Labels on the live `Namespace` object |
| Scope changes when… | You edit the policy | A namespace's labels change — no policy edit needed |
| Typical use | A small, fixed, deliberately-enumerated set | An organization-wide convention ("every namespace labeled `env: prod`") that new namespaces should automatically join |

The dynamic behavior of `namespaceSelector` cuts both ways. It's exactly what you want for "every production namespace, forever, including ones that don't exist yet" — no one has to remember to update the policy when a new team spins up a new prod namespace and labels it correctly. But it also means a namespace's scope under a policy can change from something that happened nowhere near the policy itself: someone runs `kubectl label namespace shop-dev env=prod` for an unrelated reason, and every `namespaceSelector: {env: prod}` policy in the cluster now applies to it too.

> [!WARNING]
> **A `namespaceSelector` policy is only as good as the labels underneath it**
>
> `namespaceSelector: {matchLabels: {env: prod}}` matches nothing at all in a namespace that was never labeled `env: prod` in the first place — the rule simply never sees it, with no error, no warning, no indication anything is missing. If a policy that should be protecting production appears to be doing nothing, checking `kubectl get namespace --show-labels` for the expected label is one of the first things to verify.

> [!TIP]
> **Try it — watch a namespaceSelector scope change live**
>
> ```sh
> kubectl create namespace scratch-ns
> kubectl get namespace scratch-ns --show-labels
> ```
> A rule scoped with `namespaceSelector: {matchLabels: {env: prod}}` does not apply to `scratch-ns` yet. Now:
> ```sh
> kubectl label namespace scratch-ns env=prod
> ```
> Create a matching resource in `scratch-ns` and the same rule now applies — nothing about the policy itself changed.

## Reference

- `kubectl explain clusterpolicy.spec.rules.match.any.resources.namespaceSelector` — the live schema, identical in shape to a Pod's `spec.affinity.*.namespaceSelector`.
- `kubectl label namespace <name> <key>=<value>` — the command that puts a namespace in or out of scope of every `namespaceSelector`-based policy in the cluster at once.
