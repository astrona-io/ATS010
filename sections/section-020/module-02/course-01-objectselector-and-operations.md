# Part 1 — objectSelector & Operations

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — subjects, roles, clusterRoles & any/all](./course-02-subjects-roles-clusterroles-and-any-all.md).

## `objectSelector` — labels on the resource itself

Module 1 covered `namespaceSelector`, which reads labels off the *Namespace object* a resource lives in. `objectSelector` looks somewhere different: the labels on the *matched resource itself*.

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
      namespaces:
        - apps-ns
      objectSelector:
        matchLabels:
          tier: frontend
```

This rule only considers Pods in `apps-ns` that are themselves labeled `tier: frontend` — a Pod labeled `tier: backend` in the exact same namespace is invisible to this rule.

> [!TIP]
> **`namespaceSelector` vs `objectSelector` — which labels, on which object**
>
> These two fields are easy to swap by accident because they look almost identical in YAML. The distinction that matters:
> - `namespaceSelector` → labels on the **Namespace** the resource lives in.
> - `objectSelector` → labels on the **resource being matched**, directly.
>
> A Pod itself is never affected by `namespaceSelector`'s outcome changing unless the Pod is re-evaluated (e.g. at next admission); a Pod's own labels changing on an `UPDATE` is what `objectSelector` reacts to.

> [!TIP]
> **Try it — scope a rule with objectSelector**
>
> ```sh
> kubectl run frontend-probe --image=nginx -n apps-ns --labels=tier=frontend --dry-run=client -o yaml
> kubectl run backend-probe --image=nginx -n apps-ns --labels=tier=backend --dry-run=client -o yaml
> ```
> With a rule scoped to `objectSelector.matchLabels: {tier: frontend}`, applying the first manifest triggers the rule; applying the second does not — same namespace, same Kind, different outcome purely because of the object's own labels.

## `operations` — which admission verb

Every admission request Kyverno evaluates carries an operation: `CREATE`, `UPDATE`, `DELETE`, or `CONNECT` (the last one covers subresource connections like `pods/exec`). By default, a `match` block with no `operations` field considers all applicable operations for the action type — a `validate` rule sees `CREATE` and `UPDATE` by default, for example. Setting `operations` explicitly narrows that:

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
      operations:
        - CREATE
```

Restricting to `[CREATE]` alone means the rule only ever evaluates brand-new Pods — an `UPDATE` to an already-admitted Pod (for instance, a status patch from the kubelet) never re-triggers it. This matters for two common cases:

- **Avoiding needless re-evaluation.** A validate rule that only makes sense at creation time (e.g. "the requesting user must be a specific ServiceAccount") shouldn't also fire on every subsequent `UPDATE`.
- **Deliberately letting some operations bypass a rule.** A rule restricted to `[CREATE, UPDATE]` never blocks a `DELETE` — useful when a guardrail is meant to prevent bad objects from being written, not to interfere with cleanup.

> [!WARNING]
> **Common pitfall**
>
> Leaving `operations` unset is usually fine and is what most example policies do — but if a rule behaves correctly on `kubectl apply -f` (a `CREATE`) yet appears to do nothing on a subsequent edit, or vice versa, checking whether `operations` was set (and to what) is one of the first things to look at.

## Reference

- `kubectl explain clusterpolicy.spec.rules.match.any.resources.objectSelector` — same label-selector schema as `namespaceSelector`, evaluated against a different object.
- Kubernetes API concepts documentation on admission review "operation" values, for the authoritative list beyond `CREATE`/`UPDATE`/`DELETE`/`CONNECT`.
