# Overview: Applying Beyond Admission (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno installed and a namespace that already has non-compliant workloads, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies and exceptions, break them, run `astrona destroy` and start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno v1.13.2 in the `kyverno` namespace, with its admission, background, reports and cleanup controllers running. PolicyException support is **not** enabled.
- The sandbox:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `background-ns` | Deployment `legacy-worker` | Running, no resource limits |
  | `background-ns` | Deployment `report-worker` | Running, no resource limits |

- No `ClusterPolicy`, `Policy` or `PolicyException` exists yet.

## Helpers

Paste these once in each new terminal. `failing_results` prints every failing result in a namespace (it needs `jq`). `autogen_rules` prints the names of the autogen rules of a `ClusterPolicy`. `admission_args` prints the arguments of the Kyverno admission controller.

```sh
failing_results() {
  kubectl get polr -n "$1" -o json | jq -r '.items[].results[]? | select(.result=="fail") | .policy + " / " + .rule + " / " + (.resources[0].name)'
}
autogen_rules() {
  kubectl get clusterpolicy "$1" -o jsonpath='{.status.autogen.rules[*].name}{"\n"}'
}
admission_args() {
  kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
}
```

Use them like this: `failing_results background-ns`, `autogen_rules require-limits-enforce`, `admission_args`.

## Practice tasks

- Apply an `Audit` policy for Pods in `background-ns`. Wait for the reports and find both Deployments with `failing_results background-ns`. Confirm that neither Deployment changed.
- Fix `report-worker` with `kubectl set resources` and watch its result change from `fail` to `pass`.
- Set `background: false` on the rule and apply it. Create a new Pod without limits and compare what the reports show for new Pods and for the old Deployments.
- Apply an `Enforce` policy and run `autogen_rules` to see the generated names. Try to create a new Deployment without limits and read the error.
- Set the annotation `pod-policies.kyverno.io/autogen-controllers` to `none`, apply, run `autogen_rules` again and repeat the Deployment test.
- Write a PolicyException before enabling the feature and show that it has no effect. Then enable the feature with `--enablePolicyException=true` and `--exceptionNamespace=background-ns` and test again.
- Write an exception that names only the Pod rule and show that a Deployment is still blocked. Add the `autogen-` rule name and test again.
- Create the exception in a namespace that is not the `--exceptionNamespace` and show that Kyverno ignores it.
