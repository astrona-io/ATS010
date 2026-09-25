# Part 1 — Background Scanning Already-Existing Resources

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Autogen for Pod Controllers & PolicyExceptions](./course-02-autogen-and-policyexceptions.md).

## Admission control has no memory of the past

Everything you saw in Module 1 — `Enforce` blocking, `Audit` recording — only fires at the moment the API server processes a create or update request. Apply a brand-new policy to a cluster that has been running for a year, and every resource created before that moment is simply invisible to admission control. Kyverno never re-evaluates them just because a new policy showed up.

`background: true` (the default on every rule, unless you explicitly set it to `false`) is what closes that gap. Kyverno's background controller periodically re-evaluates every matching resource already in the cluster against the rule, independent of admission control entirely.

## What background scanning is, and isn't

- It only meaningfully applies to `validate` rules. `mutate` and `generate` rules have their own, separate mechanisms for touching pre-existing resources (`mutateExistingOnPolicyUpdate` and `generateExisting`), which you'll meet in Section 030 — background scanning does not retroactively mutate or generate anything.
- It never blocks or deletes anything, regardless of `validationFailureAction`. A background scan can only ever *report* — it writes its findings into a `PolicyReport` (namespaced resources) or `ClusterPolicyReport` (cluster-scoped resources).
- It runs on its own periodic schedule, not instantly the moment you apply the policy. Expect a short delay before a report reflects a policy you just applied.

> [!TIP]
> **Try it — scan a pre-existing violator**
>
> Given a Deployment that already existed before you applied any policy:
> ```sh
> kubectl apply -f require-resource-limits.yaml   # background: true
> kubectl get policyreport -A
> ```
> The pre-existing Deployment's Pod(s) should appear as a violation in the report — with the Deployment itself completely untouched. Nothing was deleted, edited, or blocked.

## Turning background scanning off

Setting `background: false` on a rule opts it out of the periodic re-scan entirely — the rule then only ever evaluates resources at the moment they are admitted. This is worth doing when a rule's condition genuinely can't be meaningfully re-checked outside the admission context (for example, a rule that inspects `request.operation` or other request-specific metadata that doesn't exist on a resource already sitting in etcd), or when you deliberately want a rule to apply only going forward and never flag history.

> [!WARNING]
> **Common pitfall**
>
> Assuming `background: false` on a rule with `validationFailureAction: Audit` means "nothing happens." It still evaluates every new admission — `background` and `validationFailureAction` are independent settings. `background` controls whether *pre-existing* resources are periodically re-checked; `validationFailureAction` controls what happens to a resource *at admission time*, regardless of `background`.

## Reference

- `kubectl get policyreport -A` / `kubectl get clusterpolicyreport` — every background-scan (and Audit-mode) finding.
- `kubectl explain clusterpolicy.spec.rules.skipBackgroundRequests` — a related, more granular per-rule background control covered further in Section 030.
