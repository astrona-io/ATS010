# Part 3 - Cluster mode, reports and where the CLI differs

## --cluster

`--cluster` tells the CLI to read the resources from the cluster in your current `kubectl` context instead of from files. The policy still comes from a file. The CLI lists the resources that the policy's rules match, evaluates them, and prints the result. It does not create or change anything in the cluster.

```sh
kyverno apply policies/require-team-label.yaml --cluster
```

This answers a question that admission control cannot: which of the objects that already exist would fail this policy? It is the same question as a background scan, but you ask it before the policy is installed. In the lab, the Pod `legacy` was created before any policy existed, so the scan reports it and the exit code is non-zero. Use this run to size the cleanup work before you switch a policy to `Enforce`.

You can combine `--cluster` with a values file, for variables that you cannot read from the cluster. You can also combine it with `--resource` files, to test a manifest and the live objects in one run. Check `kyverno apply --help` for the other cluster-related flags in your version.

## How --cluster finds the resources

The CLI reads the kubeconfig and uses the current context, exactly as `kubectl` does. For each rule it takes the kinds in `match` and asks the API server to list objects of those kinds. Then it applies `match` and `exclude` locally and evaluates the rule on every object that remains. Because it lists objects, the identity in your kubeconfig needs `list` permission on those kinds. A permission error appears as an error from the API server, and the run does not give a result for that kind.

Check the context before every `--cluster` run:

```sh
kubectl config current-context
```

Running a scan against the wrong cluster gives a correct-looking answer about the wrong objects. In the lab there is one kind cluster, so the context is the right one. In real work, CI jobs often hold several contexts.

Two limits follow from the listing. The CLI sees only what exists at that moment, and it never watches for changes. It also lists the objects of the whole cluster for the kinds in `match`, unless the rule restricts namespaces. A broad `kinds: ["*"]` match in a large cluster is a heavy request to the API server, so restrict `match` by kind and namespace in the policy you scan with.

For a report limited to one namespace, `-n` (used with `--cluster` and `--policy-report`) restricts the report to that namespace.

## Exit codes in cluster mode

The exit code rules are the same as for files. A failed rule on any live object makes the exit code non-zero, so the command is usable as a gate: "no existing object may violate this policy before I switch it to `Enforce`". If the scan finds `legacy`, the cleanup list has one entry. Fix or delete the object, run the scan again, and continue only when the exit code is 0 and the `pass` counter is above zero, because an empty `pass` count means the match selected nothing.

## --policy-report

By default the CLI prints text. `--policy-report` makes it print a policy report instead: a `PolicyReport` for namespaced resources or a `ClusterPolicyReport` for cluster-scoped ones, in the same `wgpolicyk8s.io/v1alpha2` format that Kyverno writes in a cluster. Each result has the policy, the rule, the resource, and a result of `pass`, `fail`, `warn`, `error` or `skip`. A report in a known format is easy to parse in a pipeline, to attach to a pull request, or to compare with the report of the live cluster.

```sh
kyverno apply policies/ --resource resources/pod-nolabel.yaml --policy-report
```

The CLI only prints the report. It does not create a `PolicyReport` object.

## What a report result contains

Each entry in a policy report is one result. A result names the `policy` and the `rule`, the `result` value (`pass`, `fail`, `warn`, `error` or `skip`), a `message` for failures, and the resource it judged. The report also has a `summary` with one counter for each result value. These are the same five values as the counters that `kyverno apply` prints, so a CLI run, a CLI report and a report from the cluster use one vocabulary.

That common vocabulary is why you can compare them. Run `kyverno apply` with `--cluster --policy-report` on a policy that is already installed, and run `kubectl get policyreport -A -o json` for the same namespace. For the same objects the results should agree. A difference points to one of the causes in the table below: for example, a resource that the live webhook configuration never sends to Kyverno, or an exception that only the cluster knows.

## Where a CLI result can differ from the cluster

A green CLI run is strong evidence, not proof. The cluster has information and behaviour that a file does not. These are the main differences:

| Difference | Effect |
| --- | --- |
| The live resource has fields that the API server adds: defaults, a service account, tolerations, injected sidecars | The cluster validates the longer object. A rule can pass on your file and fail live, or the other way round |
| `request.userInfo`, `request.roles`, `request.operation` | A file has no caller and no operation. You must supply them, or the rule is not tested as it runs live |
| Namespace labels and other cluster objects (`ConfigMap`, `apiCall`) | A rule that selects namespaces by label, or reads a ConfigMap, needs the values or `--cluster` |
| Policy exceptions, exclusions and Kyverno's own resource filters | The live webhook skips system namespaces and honours `PolicyException` objects. A plain CLI run does not know about them |
| `validationFailureAction` | Live, `Enforce` blocks. In the CLI, `Enforce` and `Audit` both fail the run (unless `--audit-warn`) and nothing is blocked |
| Admission webhook configuration | A rule can match a resource kind that the Kyverno webhook is not configured to receive, so it never runs live |
| Rules that call outside systems, such as image signature checks | They need a registry and a network. Test them in a cluster |
| Version of Kyverno | The CLI is a separate binary. Use the same version as the controllers (v1.13.2 here) |

Two practical rules follow. First, pin the CLI version in your CI to the version of Kyverno that runs in the cluster. Second, treat the CLI as the fast, cheap gate and a cluster run as the final proof. The last step of the lab does exactly that: it applies the proven policy and checks with `kubectl apply --dry-run=server` that the live webhook gives the same answer as the CLI.

> [!TIP]
> **Try it - compare CLI and cluster**
>
> Apply `require-team-label` with `kubectl apply -f policies/require-team-label.yaml` and wait until it is Ready. Then run `kubectl apply --dry-run=server -f resources/pod-nolabel.yaml` and compare the message with the CLI failure. They should name the same policy and rule. Now remove `namespace: lab` from a copy of the manifest and run the CLI on it. What happens to the `skip` counter?

## A scan before an Enforce rollout

The three tools in this part fit one workflow for a new policy. First, write the policy and run it on sample files, to check the logic. Second, run it with `--cluster` to count the live objects that fail. Each failure is a cleanup task for its owner. Third, apply the policy in `Audit` mode and compare its report with the CLI scan. When both show the same objects, switch the policy to `Enforce`.

The CLI scan is cheaper than the Audit step because it does not need the policy in the cluster. It is also less complete, because it does not know about exceptions, request data or Kyverno's own filters. Use the scan to plan the work and the cluster report to confirm it.

## Putting it together in a pipeline

A typical pipeline step for a policies repository runs the CLI on every policy and a set of sample resources, with `--audit-warn` for policies that are still in `Audit`. A non-zero exit code stops the merge. After the merge, a deployment tool applies the policy to the cluster. The `kyverno test` command goes one step further: it stores the expected result next to the sample resources so that the pipeline checks them instead of you reading the output.

## Common pitfalls

- Running `--cluster` against the wrong kubectl context and trusting the answer.
- Reading `exit=0` as "the cluster is clean" when the `pass` counter is 0 and the match selected no object.
- Treating the CLI report as a `PolicyReport` object. The CLI only prints it, and nothing is stored in the cluster.
- Expecting `--cluster` to apply a policy. The command reads the cluster and never changes it.
- Using a different CLI version than the Kyverno controllers. The same policy can then give different results.
- Forgetting that a CLI run does not know about `PolicyException` objects, so a resource that is exempt in the cluster still fails the scan.
