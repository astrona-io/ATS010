# Overview: Policy-Level Settings (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno v1.13.2 and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno v1.13.2 in the `kyverno` namespace: the admission, background, cleanup and reports controllers, all ready.
- Three empty namespaces: `critical-ns`, `lenient-ns` and `sandbox`.
- No `ClusterPolicy` and no `Policy`.

## Helpers

Paste these once in each new terminal.

```sh
# Apply a Pod without the label in a namespace as a server-side dry run: shows what the webhook decides without creating anything
try_pod() {  # usage: try_pod <namespace> [label-value]
  kubectl apply --dry-run=server -n "$1" -f - <<POD
apiVersion: v1
kind: Pod
metadata:
  name: probe-pod
  ${2:+labels: {app: "$2"}}
spec:
  containers:
    - name: c
      image: nginx:alpine
POD
}
# Show the webhook entries Kyverno registered, with their failurePolicy and timeout
webhooks() {
  kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg \
    -o jsonpath='{range .webhooks[*]}{.name}{"  failurePolicy="}{.failurePolicy}{"  timeout="}{.timeoutSeconds}{"\n"}{end}'
}
# Original replica count of the admission controller, so you can restore it
kubectl -n kyverno get deploy kyverno-admission-controller -o jsonpath='{.spec.replicas}{"\n"}'
```

## Practice tasks

- Write a `ClusterPolicy` that requires an `app` label on Pods in `critical-ns` with `failurePolicy: Fail` and `webhookTimeoutSeconds: 5`. Run `webhooks` before and after, and look for how Kyverno files the policy under a webhook entry that matches its `failurePolicy`.
- Write the same policy for `lenient-ns` with `failurePolicy: Ignore`. Prove with `try_pod` that both namespaces block the unlabelled Pod while Kyverno is healthy.
- Scale `kyverno-admission-controller` to `0`, run `try_pod` on both namespaces and compare. Restore the replica count and wait for the rollout before you carry on.
- Try `webhookTimeoutSeconds: 31` and `webhookTimeoutSeconds: 0` and read the error. Then try a typo such as `validationFailureAction: Enforse`.
- Write a policy that uses `{{ request.userInfo.username }}` in a `validate` message or condition with `background: true` and read what Kyverno says. Then set `background: false` and apply again.
- Set `spec.admission: false` and `spec.background: true` on a policy and compare what a new unlabelled Pod does with what `kubectl get policyreport -A` shows a little later.
- Run `kubectl explain clusterpolicy.spec --recursive | head -80` and find every field covered in this module.
