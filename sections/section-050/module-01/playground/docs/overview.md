# Overview: Reading PolicyReport and ClusterPolicyReport (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno and some seeded resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Query the reports, change things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35 with Kyverno v1.13.2. `kubectl` is already pointed at it, as the cluster administrator. `jq` runs on your machine.
- Two `ClusterPolicy` objects, both with `validationFailureAction: Audit`:

  | Policy | Rule | Checks |
  | --- | --- | --- |
  | `require-owner-label` | `check-owner-label` | ConfigMaps in `fleet-reports` that carry the label `app=fleet` must also carry an `owner` label |
  | `require-namespace-team` | `check-team-label` | Namespaces that carry the label `demo=reports` must also carry a `team` label |

- Seeded resources:

  | Resource | State |
  | --- | --- |
  | ConfigMaps `fleet-alpha`, `fleet-bravo`, `fleet-charlie` in `fleet-reports` | compliant (have `owner`) |
  | ConfigMaps `legacy-delta`, `legacy-echo` in `fleet-reports` | violate on purpose (no `owner`) |
  | Namespace `reports-ok` | compliant (has `team`) |
  | Namespace `reports-bad` | violates on purpose (no `team`) |

The resources existed before the policies, so the first results come from a background scan. Reports can take a minute or two to appear after the cluster starts.

## Helpers

Paste these once in each new terminal. `fails` prints every failing result of the ConfigMap reports with the resource name. `cfails` does the same for cluster-scoped resources. `tally` prints how many results of each value a policy has.

```sh
fails() {
  kubectl get policyreport -A -o json | jq -r '
    .items[] as $r | $r.results[]? | select(.result == "fail")
    | [$r.metadata.namespace, ($r.scope.name // .resources[0].name // "?"), .policy, .rule] | @tsv'
}
cfails() {
  kubectl get clusterpolicyreport -o json | jq -r '
    .items[] as $r | $r.results[]? | select(.result == "fail")
    | [($r.scope.name // .resources[0].name // "?"), .policy, .rule] | @tsv'
}
tally() {
  kubectl get policyreport,clusterpolicyreport -A -o json | jq -r --arg p "$1" '
    [.items[].results[]? | select(.policy == $p) | .result] | group_by(.) | map("\(.[0]): \(length)") | .[]'
}
```

Use them like this: `fails`, `cfails`, `tally require-owner-label`.

## Practice tasks

- Run `kubectl api-resources --api-group=wgpolicyk8s.io`. Which kinds and short names exist, and which one is namespaced?
- List the reports in `fleet-reports` with `kubectl -n fleet-reports get policyreport`. Count them, then count the resources. Is the layout one report per resource or one per namespace in your cluster? Read `scope` in one report to find out.
- Print one complete report with `-o yaml`. Find `summary`, `results`, `scope` or `resources`, `policy`, `rule`, `result`, `message` and `scored`.
- Write a `jq` command that prints only the `message` of the failing results. Then write one that counts passes per policy.
- Run `kubectl get clusterpolicyreport`. Which namespaces appear as failing? Explain why `kubectl get policyreport -A` never shows them.
- Predict what `tally require-owner-label` prints before you run it. Check your prediction against the seeded resources above.
- Add a `severity` annotation to a copy of a policy (`policies.kyverno.io/severity: high`) and look for the `severity` field in a result after the reports refresh.
- Change the `scored` annotation to `"false"` on `require-owner-label` (`policies.kyverno.io/scored: "false"`) and watch which result value its failures take.
