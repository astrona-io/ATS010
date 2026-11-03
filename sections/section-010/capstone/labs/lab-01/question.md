# Question

Solve this question on: `terminal`

The platform team rolls limits out in two steps. The `checkout-live` namespace is ready for `Enforce`. The `reporting-live` namespace still has a legacy workload, so it only gets `Audit`. The namespaces `checkout-live` and `reporting-live` already exist. A Deployment named `old-reporter` already exists in `reporting-live` with no resource limits set. PolicyException support is not enabled.

1.  Write a `ClusterPolicy` named `checkout-require-limits` with a validate rule named `check-limits-checkout` that requires every container of every Pod in `checkout-live` to set `resources.limits.cpu` and `resources.limits.memory`. Use `validationFailureAction: Enforce` and `background: true`.
2.  Write a second `ClusterPolicy` named `reporting-audit-limits` with the same validation shape and a rule named `check-limits-reporting`, scoped to `reporting-live`, using `validationFailureAction: Audit` and `background: true`.
3.  Apply both policies. Try to create a Pod named `no-limits-checkout` in `checkout-live` with no resource limits, and confirm it is rejected. Create a Pod named `no-limits-reporting` in `reporting-live` with no resource limits, and confirm it is admitted.
4.  Confirm `old-reporter` in `reporting-live` still exists, is unmodified, and shows up as a violation in `kubectl get policyreport -n reporting-live`.
5.  Enable PolicyExceptions by adding `--enablePolicyException=true` and `--exceptionNamespace=checkout-live` to the `kyverno-admission-controller` Deployment, and wait for the rollout. Then create a `PolicyException` named `allow-migration-job` in `checkout-live` that exempts resources named `migration-job*` from the rule `check-limits-checkout` of `checkout-require-limits`. Make sure it also covers the check that runs when a Job is created. Create a Job named `migration-job` in `checkout-live` with no resource limits and confirm it is admitted.

The final state must have both policies in place, `no-limits-checkout` absent, `no-limits-reporting` and `old-reporter` running, and `migration-job` created.
