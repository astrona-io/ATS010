# Part 2 — subjects, roles, clusterRoles & any/all

> Prerequisite: [Part 1 — objectSelector & Operations](./course-01-objectselector-and-operations.md). Next: [Section Overview](../README.md).

## `any` / `all` — OR and AND across selection blocks

Every example so far has quietly used `match.any`, a list containing exactly one `resources` block. `any` and `all` are how Kyverno lets a single rule express more than one independent selection condition:

- **`any`** — the rule matches if **at least one** listed block matches (logical OR).
- **`all`** — the rule matches only if **every** listed block matches (logical AND).

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
      namespaces:
        - apps-ns
  - resources:
      kinds:
        - Pod
      namespaces:
        - staging-ns
```

This example matches a Pod in `apps-ns` **or** a Pod in `staging-ns` — two independent conditions, either one sufficient. Contrast with a single block using `all` inside it:

```yaml
match:
  all:
  - resources:
      kinds:
        - Pod
      namespaces:
        - apps-ns
      objectSelector:
        matchLabels:
          tier: frontend
```

Here, `kinds`, `namespaces`, and `objectSelector` inside one `resources` block are already implicitly ANDed together — a resource must satisfy all of them at once regardless of whether the outer list is `any` or `all`. The outer `any`/`all` choice matters once you have **more than one** `resources` block (or a mix of `resources` and `subjects`), and need to say whether satisfying one of them is enough, or all of them are required together.

`exclude` uses the exact same `any`/`all` structure — an `exclude.any` list carves a resource out of scope if it matches *any* of the listed exclusion blocks.

## `subjects` — matching the requester's identity

Every admission request Kyverno evaluates carries the identity of whoever (or whatever) sent it — a human `User`, a `Group` they belong to, or a `ServiceAccount` a workload or CI pipeline authenticates as. `subjects` lets a `match` or `exclude` block key off that identity directly:

```yaml
exclude:
  any:
  - subjects:
      - kind: ServiceAccount
        name: ci-deployer
        namespace: apps-ns
```

This is one of the most common real-world uses of `exclude`: a human-facing guardrail (say, "every Pod must set resource limits") shouldn't necessarily block a CI/CD pipeline's automated deploy identity, which may have its own separate review gate upstream. Excluding by `subjects` lets that one identity bypass the rule without weakening it for anyone else.

> [!TIP]
> **Try it — impersonate a ServiceAccount and watch an exclude take effect**
>
> ```sh
> kubectl --as=system:serviceaccount:apps-ns:ci-deployer auth can-i create pods -n apps-ns
> ```
> Assuming the RBAC binding exists, this confirms impersonation is set up. With a policy excluding `subjects: [{kind: ServiceAccount, name: ci-deployer, namespace: apps-ns}]`, creating a resource while impersonating that identity (`kubectl --as=system:serviceaccount:apps-ns:ci-deployer run ...`) skips the rule entirely, while the exact same manifest applied as your normal identity is still evaluated by it.

## `roles` / `clusterRoles` — matching by RBAC binding

`roles` and `clusterRoles` take a related but distinct approach: instead of naming a specific identity, they match any requester whose RBAC bindings grant them a specific `Role` or `ClusterRole`.

```yaml
match:
  any:
  - resources:
      kinds:
        - Secret
    clusterRoles:
      - cluster-admin
```

This requires Kyverno to perform a live RBAC lookup for the requester at admission time to determine which roles apply to them — a more indirect (and, in practice, less commonly reached-for) mechanism than `subjects`, since it depends on the current state of `RoleBinding`/`ClusterRoleBinding` objects rather than a name you write directly into the policy. `subjects` is generally the simpler, more predictable choice when you know exactly which identity you want to target or exempt; `roles`/`clusterRoles` are useful when the intent is genuinely "anyone holding this permission level," independent of which specific account that happens to be today.

> [!WARNING]
> **Common pitfall**
>
> `roles`/`clusterRoles` matching depends on Kyverno being able to resolve the requester's effective RBAC bindings at admission time. If bindings change (a `ClusterRoleBinding` is added or removed), the set of identities a `roles`/`clusterRoles`-based rule applies to changes immediately too — the same "dynamic scope" behavior you saw with `namespaceSelector`, just driven by RBAC state instead of namespace labels.

## Reference

- `kubectl explain clusterpolicy.spec.rules.match.any.subjects` — the live schema for `kind`/`name`/`namespace` under `subjects`.
- `kubectl auth can-i --as=<identity> <verb> <resource>` — the standard way to sanity-check an identity's effective permissions before relying on `roles`/`clusterRoles` matching in a policy.
