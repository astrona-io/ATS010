# Question

Solve this question on: `terminal`

The platform team turns on a resource-limits rule in `background-ns`. The namespace already exists, and a Deployment named `legacy-worker` is already running in it with no resource limits set on its container. Kyverno is installed, but PolicyException support is not enabled.

1.  Write a `ClusterPolicy` named `require-resource-limits-bg` with a validate rule named `check-resource-limits-bg` that matches `Pod` resources in the `background-ns` namespace and requires `resources.limits.cpu` and `resources.limits.memory` on every container. Set `validationFailureAction: Enforce` and `background: true`.
2.  Apply the policy. Inspect it with `kubectl get clusterpolicy require-resource-limits-bg -o yaml` and confirm Kyverno's autogen mechanism added rules for Deployment-owning controllers.
3.  Confirm the background scan reports the pre-existing `legacy-worker` Deployment in `kubectl get policyreport -n background-ns`, without deleting or modifying it. Do this before you create the exception, because the report changes afterwards.
4.  Try to create a new Deployment named `new-worker` in `background-ns` with no resource limits. Confirm it is rejected.
5.  Enable PolicyExceptions by patching the `kyverno-admission-controller` Deployment in the `kyverno` namespace to add the container arguments `--enablePolicyException=true` and `--exceptionNamespace=background-ns`, then wait for the rollout to finish.
6.  Create a `PolicyException` named `allow-legacy-worker` in `background-ns` that exempts resources named `legacy-worker*` from the `check-resource-limits-bg` rule of `require-resource-limits-bg`. Make sure it also covers the check that runs when the Deployment itself is updated.
7.  Force `legacy-worker` to roll a new Pod, for example by adding an annotation to its Pod template. Confirm the new Pod is admitted although it still has no resource limits.

The final state must have the policy in `Enforce` mode, `new-worker` absent, the exception in place and `legacy-worker` ready.
