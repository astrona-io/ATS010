# Part 1 — Selecting by Kind, Name & Wildcards

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Namespaces & namespaceSelector](./course-02-namespaces-and-namespaceselector.md).

## `resources.kinds` — what shape of object

The first thing every `match` block usually declares is *which Kind of resource* it cares about:

```yaml
match:
  any:
  - resources:
      kinds:
        - Pod
```

`kinds` is a list, so a single rule can watch several object types at once — for example `[Pod, Deployment, StatefulSet]` for a rule that applies the same check across every workload shape.

Most of the time a bare Kind name (`Pod`, `ConfigMap`, `Ingress`) is unambiguous. But some Kind names exist in more than one API group at different versions — for example a cluster running both a built-in `Ingress` and a CRD that also happens to be called something generic. When Kyverno needs to know exactly which API resource you mean, you qualify the entry as `group/version/Kind`:

```yaml
kinds:
  - apps/v1/Deployment
  - networking.k8s.io/v1/Ingress
```

> [!TIP]
> **Try it — see the fully-qualified kind**
>
> ```sh
> kubectl api-resources -o wide | grep -i deployment
> ```
> The `APIVERSION` column (`apps/v1`) combined with the `KIND` column is exactly the `group/version/Kind` string Kyverno expects when you need to disambiguate.

## `name` vs `names`

Once `kinds` narrows the *type*, `name`/`names` can narrow the *specific object(s)*:

| Field | Shape | Use case |
| --- | --- | --- |
| `name` | Single string, wildcard-capable | One specific object, or one wildcard pattern |
| `names` | List of strings, each wildcard-capable | Several specific objects or patterns in one rule |

```yaml
resources:
  kinds:
    - ConfigMap
  names:
    - "prod-*"
    - "canary-*"
```

This matches any `ConfigMap` whose name starts with `prod-` **or** starts with `canary-` — the list is evaluated as OR.

## The `*` wildcard

The `*` character in a `name`/`names` entry matches any sequence of characters (including none) at that position in the string. It is a simple glob, not a regular expression — there's no character class syntax, no anchoring token beyond the implicit "the rest of the string must match literally."

> [!WARNING]
> **A wildcard on `name` is not a security boundary**
>
> Consider a rule scoped to `names: ["*-secrets"]` intending to catch every `ConfigMap` holding sensitive data. This looks precise, but `name` matching only ever inspects the string in `metadata.name` — it says nothing about the object's actual *content*. A `ConfigMap` named `app-secrets` that stores nothing sensitive is caught by the rule; a `ConfigMap` named `credentials` (no `-secrets` suffix) that stores an actual password sails straight through unmatched. Naming conventions are a hint for humans, not a security control Kyverno enforces on your behalf. If the goal is genuinely "catch anything holding sensitive data," you need a rule based on the object's actual keys/labels, not its name string.
>
> This is also why `names: ["*-secrets"]` alone is a fragile way to scope a policy: anyone who creates a `ConfigMap` under a different name entirely skips the rule, whether that's an oversight or deliberate.

> [!TIP]
> **Try it — match by a wildcard name**
>
> Write (don't apply yet — just draft) a rule fragment that only matches `ConfigMap`s whose name ends in `-secrets`:
> ```yaml
> match:
>   any:
>   - resources:
>       kinds:
>         - ConfigMap
>       names:
>         - "*-secrets"
> ```
> Mentally check it against `db-secrets` (matches), `secrets-db` (does **not** match — the wildcard only covers the leading portion here, the trailing `-secrets` must be literal), and `app-secrets-v2` (does **not** match — the string must *end* in `-secrets`, and `-v2` breaks that).

## Reference

- `kubectl explain clusterpolicy.spec.rules.match.any.resources` — the live schema for `kinds`/`name`/`names` on your installed Kyverno CRD version.
- `kubectl api-resources` — the authoritative list of Kind names and their API groups/versions available on your cluster.
