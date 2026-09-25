# Question

Solve this question on: `terminal`

1.  Write a `ClusterPolicy` named `require-app-label-strict` with a validate rule matching Pods in the `critical-ns` namespace, requiring a non-empty `app` label. Set `validationFailureAction: Enforce`, `failurePolicy: Fail`, and `webhookTimeoutSeconds: 5`.
2.  Write a second `ClusterPolicy` named `require-app-label-lenient` with the identical validate rule shape but matching Pods in the `lenient-ns` namespace instead. Set `validationFailureAction: Enforce`, `failurePolicy: Ignore`, and `webhookTimeoutSeconds: 5`.
3.  Apply both policies.
4.  Create a Pod named `no-app-pod` with no `app` label in `critical-ns`, and confirm the API server rejects it.
5.  Create a Pod named `has-app-pod` with the label `app: checkout` in `critical-ns`, and confirm it is admitted.
6.  Create a Pod named `no-app-pod` with no `app` label in `lenient-ns`, and confirm the API server rejects it.
7.  Create a Pod named `has-app-pod` with the label `app: checkout` in `lenient-ns`, and confirm it is admitted.

Exploratory only, not graded: try scaling `kyverno-admission-controller` down to `0` replicas and observe the different failure-mode behavior of the two policies when Kyverno itself is unreachable, then scale it back to its original ready replica count before you finish — the validation checks that the admission controller is healthy and running at the end.
