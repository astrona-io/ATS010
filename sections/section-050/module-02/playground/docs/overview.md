# Overview: Where Results Come From and How They Age (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno and some seeded resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Change resources and policies, watch the reports follow, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35 with Kyverno v1.13.2. `kubectl` is already pointed at it, as the cluster administrator. `jq` runs on your machine.
- The `ClusterPolicy` `require-owner-label` (rule `check-owner-label`), `Audit`, checking ConfigMaps labelled `app=fleet` in `fleet-reports` for an `owner` label. The `require-namespace-team` policy for Namespaces also exists, as in the previous playground.
- Seeded resources:

  | Namespace | Resources |
  | --- | --- |
  | `fleet-reports` | `fleet-alpha`, `fleet-bravo`, `fleet-charlie` (compliant), `legacy-delta`, `legacy-echo` (violate) |
  | `rollout-lab` | `ok-1` (compliant), `bad-1`, `bad-2`, `bad-3` (violate). No policy matches this namespace yet |

## The gate policy

Apply this policy for the rollout-gate exercise. It is the same rule, aimed at `rollout-lab`, starting in `Audit`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-owner-label-gate
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-owner-label
      match:
        any:
          - resources:
              kinds: [ConfigMap]
              namespaces: [rollout-lab]
              selector:
                matchLabels:
                  app: fleet
      validate:
        message: "ConfigMaps labelled app=fleet must carry an owner label."
        pattern:
          metadata:
            labels:
              owner: "?*"
```

To re-apply `require-owner-label` after you deleted it, copy this rule with `namespaces: [fleet-reports]` and the policy name `require-owner-label`.

## Helpers

Paste these once in each new terminal. `results` prints `result`, resource name for one policy in one namespace. `watch_results` repeats it every 5 seconds so you can time how long a change takes to show up. `scan_interval` prints the reports controller's arguments.

```sh
results() {
  kubectl -n "$1" get policyreport -o json | jq -r --arg p "$2" '
    .items[] as $r | $r.results[]? | select(.policy == $p)
    | [.result, ($r.scope.name // .resources[0].name // "?")] | @tsv' | sort
}
watch_results() {
  while true; do date +%T; results "$1" "$2"; echo; sleep 5; done
}
scan_interval() {
  kubectl -n kyverno get deploy kyverno-reports-controller -o jsonpath='{.spec.template.spec.containers[0].args}'; echo
}
```

Use them like this: `results fleet-reports require-owner-label`, `watch_results rollout-lab require-owner-label-gate`, `scan_interval`.

## Practice tasks

- Run `scan_interval`. Is `--backgroundScanInterval` listed, and what is the default if it is not?
- Run `kubectl api-resources --api-group=reports.kyverno.io`. Are the ephemeral report kinds installed? If so, list them while you create a ConfigMap and see whether you can catch one.
- Create a violating ConfigMap in `fleet-reports` (label `app=fleet`, no `owner`) and time with `watch_results` how long its `fail` takes to appear.
- Fix it with `kubectl label` and time the change from `fail` to `pass`. Then delete it and time the disappearance.
- Delete `require-owner-label`, read the reports, and re-apply it. Do the old results come back by themselves, and how fast?
- Run the whole rollout gate on `require-owner-label-gate`: apply it in `Audit`, list violators, fix `bad-1` and `bad-2`, delete `bad-3`, wait for zero `fail`, patch to `Enforce`, then test with `kubectl -n rollout-lab create --dry-run=server -f <file>`.
- Create a violating ConfigMap after the flip and note that `Enforce` rejects it and no `fail` result appears for it.
- Add `spec.emitWarning: true` to a copy of the policy in `Audit` and create a violating ConfigMap. Does `kubectl` print a warning? Check the field first with `kubectl explain clusterpolicy.spec.emitWarning`.
- Enable PolicyExceptions (the flag `--enablePolicyException=true` and `--exceptionNamespace` on the admission, background and reports controllers) and write an exception for one violator. Look for a `skip` result and note whether the background results show it too.
