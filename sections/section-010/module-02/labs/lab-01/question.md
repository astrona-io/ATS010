# Question

Solve this question on: `terminal`

The `background-ns` namespace already exists, and a Deployment named `legacy-worker` is already running in it with no resource limits set on its container.

1.  Write a `ClusterPolicy` named `require-resource-limits-bg` with a validate rule matching `Pod` resources in the `background-ns` namespace, requiring `resources.limits.cpu` and `resources.limits.memory` on every container. Set `validationFailureAction: Enforce` and `background: true`.
2.  Apply the policy. Inspect it with `kubectl get clusterpolicy require-resource-limits-bg -o yaml` and confirm Kyverno's autogen mechanism added rules/annotations covering Deployment-owning controllers.
3.  Confirm the background scan reports the pre-existing `legacy-worker` Deployment's Pod as a violation in `kubectl get policyreport -n background-ns`, without deleting or modifying it.
4.  Attempt to create a brand-new Deployment named `new-worker` in `background-ns` with no resource limits set. Confirm it is rejected.
5.  Enable PolicyExceptions on the cluster by patching the `kyverno-admission-controller` Deployment in the `kyverno` namespace to add the container args `--enablePolicyException=true` and `--exceptionNamespace=background-ns`, then wait for the rollout to complete.
6.  Create a `PolicyException` named `allow-legacy-worker` in `background-ns` that exempts resources named `legacy-worker*` from the `check-resource-limits-bg` rule of `require-resource-limits-bg`.
7.  Force `legacy-worker` to roll a new Pod (for example, by adding an annotation to its Pod template) and confirm the new Pod is admitted despite still having no resource limits, proving the exception works.
