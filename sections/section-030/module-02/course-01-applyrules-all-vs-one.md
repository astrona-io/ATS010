# Part 1 — applyRules: All vs One

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — generateExisting & mutateExistingOnPolicyUpdate](./course-02-generateexisting-and-mutateexistingonpolicyupdate.md).

## The default: every matching rule runs

A `ClusterPolicy` or `Policy` can carry more than one rule under `spec.rules`. By default, Kyverno evaluates every single rule independently against a given resource — if three rules all match, all three run, cumulatively.

That default is `spec.applyRules: "All"`, and you rarely need to write it out because it's already the behavior you get. It's the right model whenever your rules are additive: a label-adding mutate rule and a resource-limit validate rule on the same Pod are two independent checks that should both apply if both match.

## applyRules: "One" — stop after the first match

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: label-namespace-by-tier
spec:
  applyRules: "One"
  rules:
    - name: gold-tier-override
      match:
        any:
        - resources:
            kinds:
              - Namespace
            selector:
              matchLabels:
                tier: gold
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: premium

    - name: standard-tier-default
      match:
        any:
        - resources:
            kinds:
              - Namespace
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: standard
```

Some rule lists are not additive — they're a priority-ordered decision tree, where you want exactly *one* outcome, not a cumulative stack of them. That's what `applyRules: "One"` is for: Kyverno evaluates `spec.rules` in order and stops as soon as the first rule whose `match` (and `exclude`) actually selects the resource has run — every rule after that is skipped for this resource, even if it would otherwise have matched too.

In the example above, a `Namespace` labeled `tier: gold` matches both rules — `gold-tier-override` because of its label selector, and `standard-tier-default` because it matches every `Namespace` with no further filter. With `applyRules: "One"`, only `gold-tier-override` runs (it's listed first and it matches), so the namespace gets `cost-center: premium` and never also gets `cost-center: standard` from the fallback rule. A `Namespace` with no `tier` label doesn't match the first rule at all, so Kyverno falls through to `standard-tier-default` and applies it instead — exactly the switch/case behavior a plain rule list can't express on its own.

> [!TIP]
> **Try it — order matters**
>
> With `applyRules: "One"`, rule order inside `spec.rules` is not cosmetic — it's the priority list. Put a narrow, specific rule (like the gold-tier override) before a broad catch-all rule, the same way you'd order `case` branches from most specific to a final `default`. Reversing the order in the example above would mean the catch-all always wins, since it matches everything and is now evaluated first.

> [!WARNING]
> **Common pitfall**
>
> `applyRules: "One"` only decides *how many rules in this policy run* against a given resource. It has no effect at all on how many separate *policies* apply — every other `ClusterPolicy`/`Policy` in the cluster that matches the resource still runs normally, regardless of this setting.

## Reference

- `kubectl explain clusterpolicy.spec.applyRules`
