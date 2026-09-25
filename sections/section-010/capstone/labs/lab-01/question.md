# Question

Solve this question on: `terminal`

The namespaces `checkout-live` and `reporting-live` already exist. A Deployment named `old-reporter` already exists in `reporting-live` with no resource limits set.

1.  Write a `ClusterPolicy` named `checkout-require-limits` with a validate rule requiring every container of every Pod in `checkout-live` to set `resources.limits.cpu` and `resources.limits.memory`. Use `validationFailureAction: Enforce` and `background: true`.
2.  Write a second `ClusterPolicy` named `reporting-audit-limits` with the same validation shape, scoped instead to `reporting-live`, using `validationFailureAction: Audit` and `background: true`.
3.  Apply both policies. Attempt to create a Pod named `no-limits-checkout` in `checkout-live` with no resource limits, and confirm it is rejected. Create a Pod named `no-limits-reporting` in `reporting-live` with no resource limits, and confirm it IS admitted.
4.  Confirm `old-reporter` in `reporting-live` still exists, is unmodified, and shows up as a violation in `kubectl get policyreport -n reporting-live`.
5.  Enable PolicyExceptions on the cluster (`--enablePolicyException=true`, `--exceptionNamespace=checkout-live` on `kyverno-admission-controller`), then create a `PolicyException` named `allow-migration-job` in `checkout-live` that exempts resources named `migration-job*` from `checkout-require-limits`. Create a Job named `migration-job` in `checkout-live` with no resource limits set, and confirm it is admitted.
