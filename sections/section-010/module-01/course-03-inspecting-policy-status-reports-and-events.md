# Inspecting Policy Status, Reports and Events

A policy that you cannot inspect is a policy you cannot trust. After you apply a policy you need to answer three questions: is Kyverno using it, what did it decide, and why. This part shows where Kubernetes and Kyverno store the answers.

## Is the policy ready

Every policy object has a `status`. Kyverno updates it while it loads the policy. The commands in this part use the `require-team-label` policy in `Audit` mode (`validationFailureAction: Audit`, matching Pods in `payments`). Apply it again if you deleted it, and create a Pod without a `team` label. `kubectl get` prints a summary table:

<!-- astrona:playground:renew -->

```sh
kubectl get clusterpolicy
```

The columns include `ADMISSION`, `BACKGROUND` and `READY`. `ADMISSION` is `true` when the rules are checked at admission time. `BACKGROUND` is `true` when the rules are also used to scan resources that already exist. `READY` is `true` when Kyverno has loaded the policy and can evaluate it. The table also shows a `MESSAGE` column that is filled when something is wrong.

In Kyverno 1.13 the status holds a `Ready` condition, and older versions only have `status.ready`. Read either one directly, for example in a script:

```sh
kubectl get clusterpolicy require-team-label -o jsonpath='{.status.ready}'
kubectl get clusterpolicy require-team-label -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
kubectl wait --for=condition=Ready clusterpolicy/require-team-label --timeout=60s
```

Use `kubectl wait` after an apply so that a script does not continue before Kyverno is ready. The first call may print nothing on a version that does not fill that field. In that case use the other field.

## Why is it not ready

`kubectl describe` prints the same status plus the Kubernetes events that Kyverno recorded for the policy:

```sh
kubectl describe clusterpolicy require-team-label
```

Look at the `Status` and `Events` sections. If a policy refers to a resource that Kyverno cannot read, or has an error that only shows up during loading, the message appears there. `kubectl explain clusterpolicy.spec` shows the field list of the Kyverno version in your cluster. Use it instead of an older documentation page when a field is rejected.

## What did the policy decide

Kyverno records results in report objects from the `wgpolicyk8s.io/v1alpha2` API group. A `PolicyReport` holds results for namespaced resources. A `ClusterPolicyReport` holds results for cluster-scoped resources. The short names are `polr` and `cpolr`. Recent Kyverno versions create one report per scanned resource, so a namespace usually has several reports.

Each report has a `summary` with the counts `pass`, `fail`, `warn`, `error` and `skip`, and a `results` list. A result names the `policy`, the `rule`, the `result` and the `resources` it applies to. Both Audit decisions at admission and results from the background scan end up here.

Print every failing result in `payments`. This works after you applied `require-team-label` in `Audit` mode and created a Pod such as `no-team-pod` without a `team` label. The command needs `jq`:

```sh
kubectl get polr -n payments -o json | jq -r '.items[].results[]? | select(.result=="fail") | .policy + " / " + .rule + " / " + (.resources[0].name)'
```

You see one line for each failing resource, with the policy, the rule and the name of the Pod. Reports are created by Kyverno controllers, so there is a short delay after the admission before a result appears.

## Events and webhooks

Kyverno also writes Kubernetes events for policy decisions. List the events in the namespace and read the most recent ones:

```sh
kubectl get events -n payments --sort-by=.lastTimestamp
```

The event reasons and the objects they are attached to can differ between Kyverno versions. If you filter with `--field-selector reason=...` and see nothing, list all events first and then narrow the filter.

The reason that a policy affects the API server at all is a set of webhook configurations that Kyverno builds itself. Kyverno updates them from the `match` blocks of the live policies:

```sh
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

You see entries whose names start with `kyverno`. The resource webhook decides which kinds of request reach Kyverno, so a policy that matches `Pod` makes Kyverno appear in the admission path for Pods. You do not edit these objects. Kyverno restores them.

You can now apply a policy, choose its failure action and check what it did. The question that remains is how to reach resources that were created before the policy existed.

## Common pitfalls

> [!WARNING]
> - Reading `READY` once and not again. Run `kubectl wait` or repeat the command, because Kyverno needs a moment after the apply.
> - Looking for a report in the wrong namespace. A `PolicyReport` lives in the namespace of the resource, not in the namespace of a `ClusterPolicy`.
> - Treating an empty report list as "no violations". It can also mean Kyverno has not written the result yet.

## Your mission: Enforce-Mode Resource Limits Policy Lab

You can now apply a policy, switch it from `Audit` to `Enforce` and prove each stage. The mission asks you to write a `require-resource-limits` policy, watch an `Audit` violation get admitted and reported, switch to `Enforce`, and prove that a violator is blocked and a compliant Pod is admitted.

Pause the playground, then run and submit the lab:

```sh
astrona stop ats-010-playground-010-01
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
```

When the lab passes, clean up and resume your playground:

```sh
astrona destroy ats-010-lab-001
astrona start ats-010-playground-010-01
```
