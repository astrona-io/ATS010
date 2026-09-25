# Part 2 — schemaValidation & Policy-wide background

> Prerequisite: [Part 1 — failurePolicy & webhookTimeoutSeconds](./course-01-failurepolicy-and-webhooktimeoutseconds.md). Next: [Module 2 — Rule-Level Settings](../module-02/course.md).

## schemaValidation: Kyverno checking its own homework

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label-strict
spec:
  schemaValidation: true   # default
  rules: [ ... ]
```

`spec.schemaValidation` defaults to `true`, and it means exactly what it sounds like: when you `kubectl apply` a policy, Kyverno validates the policy resource itself against its own internal schema — checking that `match`, `exclude`, `validate`, `mutate`, and `generate` blocks are shaped the way Kyverno expects — before it ever starts using that policy to evaluate other resources.

This is the safety net that catches a typo'd field name or an invalid combination (like a `validate` and `mutate` block on the same rule) at apply time, with a clear error message, instead of letting a broken policy silently apply to zero resources or behave in some undefined way.

Setting `schemaValidation: false` disables that check. In practice this is rare, and mostly shows up as a workaround when a policy needs to use an experimental or very new field that Kyverno's schema validator doesn't yet recognize on an older Kyverno version. Turning it off trades away Kyverno's own typo/shape protection — it is not a setting to reach for casually, and it does not change enforcement behavior (`validationFailureAction`, `failurePolicy`) at all, only whether the *policy resource itself* gets pre-flight-checked.

> [!WARNING]
> **Common pitfall**
>
> `schemaValidation: false` is sometimes mistaken for a way to relax how strictly a policy validates *other resources*. It does nothing of the sort — it only affects whether Kyverno checks the shape of the policy YAML you're applying. The pattern/deny logic inside your rules validates resources exactly the same either way.

## background, revisited as a deliberate setting

You met `spec.background` in Section 010 as the switch that makes Kyverno periodically re-scan resources that already exist, independent of admission control. It's worth returning to it here as one of the "common settings" you configure on every policy, not just something you leave at its default.

```yaml
spec:
  background: true   # default
```

`background` defaults to `true`. The case for deliberately setting it to `false` is specific: a validate rule that inspects data only present at admission time — most commonly `request.operation` (was this a `CREATE`, `UPDATE`, `DELETE`, or `CONNECT`?) or other fields unique to the live `AdmissionReview` object — cannot be meaningfully re-evaluated during a background scan, because a background scan has no admission request to inspect; it only has the resource's current state sitting in the cluster.

If you leave `background: true` on a rule like that, Kyverno's periodic scan either silently skips the parts of the rule it can't evaluate, or produces a report entry that doesn't mean what you think it means. Setting `background: false` is the honest signal: "this rule is admission-only by design," and it also saves the background-scan controller the wasted work of repeatedly trying to re-evaluate a rule it fundamentally can't check outside admission.

> [!TIP]
> **Rule of thumb**
>
> If a rule's logic ever references `request.operation`, or anything else that only exists on the live `AdmissionReview` payload rather than the resource's own persisted fields, set `background: false` on it. If the rule only ever inspects fields that live permanently on the resource (labels, spec fields, annotations), leaving `background: true` is almost always correct and lets background scanning and PolicyReports work as expected.

## Reference

- `kubectl explain clusterpolicy.spec.schemaValidation`
- `kubectl explain clusterpolicy.spec.background`
