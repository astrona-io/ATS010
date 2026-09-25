# Part 2 — Enforce vs Audit at Apply Time

> Prerequisite: [Part 1 — Applying ClusterPolicy & Policy with kubectl](./course-01-applying-clusterpolicy-and-policy-with-kubectl.md). Next: [Module 2 — Applying Beyond Admission](../module-02/course.md).

## One field decides whether a violation blocks or just gets logged

`spec.validationFailureAction` (set at the policy level, and overridable per-rule) is the single field that decides what happens to a resource that fails a `validate` rule at admission time:

| Value | What happens to the failing resource |
| --- | --- |
| `Enforce` | The API server rejects the request outright. The `kubectl apply`/`kubectl run` that created it fails with an admission error naming the policy and the reason. |
| `Audit` | The request is admitted normally — the resource is created — but the violation is recorded as a finding in a `PolicyReport` (namespaced) or `ClusterPolicyReport` (cluster-scoped). |

Both values only affect admission-time behavior for the resource being created or updated right now. Neither one reaches back and touches resources that already existed before the policy was applied — that is a different mechanism, covered in the next module.

> [!TIP]
> **Try it — watch a violation get admitted and reported under Audit**
>
> ```sh
> kubectl apply -f require-team-label.yaml   # validationFailureAction: Audit
> kubectl run no-team-pod --image=nginx:alpine -n payments
> kubectl get pod no-team-pod -n payments      # exists — it was admitted
> kubectl get policyreport -n payments         # shows the violation
> ```
>
> Now edit the file to `validationFailureAction: Enforce`, re-apply, and try creating a second non-compliant Pod. This time the API server rejects it.

## Why teams ship new policies as Audit first

Turning on `Enforce` for a brand-new rule against a live, already-busy cluster is risky: if the rule's `match`/`pattern` is even slightly wrong, it can start rejecting perfectly legitimate workloads the moment it goes live — including, in a worst case, Kyverno's own control-plane Pods or a critical platform component. The standard rollout pattern is:

1. Apply the policy with `validationFailureAction: Audit`.
2. Let it run for a representative period (hours to days, depending on your traffic patterns) while watching `PolicyReport`/`ClusterPolicyReport` objects for unexpected violations.
3. Fix the rule (or fix the workloads) until the reports look the way you expect.
4. Flip `validationFailureAction` to `Enforce` and re-apply.

## Rolling out gradually with validationFailureActionOverrides

Flipping a policy straight from `Audit` to `Enforce` cluster-wide is still an all-or-nothing move. `spec.validationFailureActionOverrides` lets you set a different `validationFailureAction` per namespace (or per namespace label selector) inside the same policy — for example, `Enforce` in a namespace where you've already fixed every violation, while the rest of the cluster stays on `Audit` a little longer. This is the mechanism for a staged, namespace-by-namespace rollout without maintaining separate copies of the same policy.

## Reference

- `kubectl get policyreport -A` / `kubectl get clusterpolicyreport` — where Audit-mode (and background-scan) findings live.
- `kubectl explain clusterpolicy.spec.validationFailureActionOverrides` — the live schema for scoped overrides.
