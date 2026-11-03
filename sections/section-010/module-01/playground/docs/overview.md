# Overview: Getting a Policy Live (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno installed and a small sandbox, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, run `astrona destroy` and start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno v1.13.2 in the `kyverno` namespace, with its four controllers running: admission, background, reports and cleanup.
- The sandbox:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `payments` | Deployment `ledger` | A running workload with no `team` label and no resource limits |
  | `platform-ns` | (empty) | A second namespace for scope and rollout tests |

- No `ClusterPolicy`, `Policy` or `PolicyException` exists yet.

## Helpers

Paste these once in each new terminal. `policy_ready` prints the `READY` state of a `ClusterPolicy`. `failing_results` prints every failing result in a namespace (it needs `jq`).

```sh
policy_ready() {
  kubectl get clusterpolicy "$1" -o jsonpath='{.status.ready}{"\n"}'
}
failing_results() {
  kubectl get polr -n "$1" -o json | jq -r '.items[].results[]? | select(.result=="fail") | .policy + " / " + .rule + " / " + (.resources[0].name)'
}
```

Use them like this: `policy_ready require-team-label`, `failing_results payments`.

## Practice tasks

- Apply a `ClusterPolicy` in `Audit` mode that requires a `team` label on Pods in `payments`. Create a Pod without the label and find the failure with `failing_results payments`.
- Run `kubectl apply --dry-run=server` and `kubectl diff` after you change `Audit` to `Enforce`. Compare their output, then apply for real.
- Break a policy on purpose (two action types in one rule) and read the error from `kubectl apply`.
- Create a namespaced `Policy` in `payments` and the same rule in `platform-ns`. Predict which Pods each one checks, then test.
- Use `validationFailureActionOverrides` to enforce in `payments` and audit everywhere else.
- Read `kubectl describe clusterpolicy` and the events in `payments` after each change.
