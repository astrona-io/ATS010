# Part 3 - Cluster mode, reports and where the CLI differs

## --cluster

`--cluster` tells the CLI to read the resources from the cluster in your current `kubectl` context instead of from files. The policy still comes from a file. The CLI lists the resources that the policy's rules match, evaluates them, and prints the result. It does not create or change anything in the cluster.

```sh
kyverno apply policies/require-team-label.yaml --cluster
```

This answers a question that admission control cannot: which of the objects that already exist would fail this policy? It is the same question as a background scan (section 010), but you ask it before the policy is installed. In the lab, the Pod `legacy` was created before any policy existed, so the scan reports it and the exit code is non-zero. Use this run to size the cleanup work before you switch a policy to `Enforce`.

You can combine `--cluster` with a values file, for variables that you cannot read from the cluster. You can also combine it with `--resource` files, to test a manifest and the live objects in one run. Check `kyverno apply --help` for the other cluster-related flags in your version.

## --policy-report

By default the CLI prints text. `--policy-report` makes it print a policy report instead: a `PolicyReport` for namespaced resources or a `ClusterPolicyReport` for cluster-scoped ones, in the same `wgpolicyk8s.io/v1alpha2` format that Kyverno writes in a cluster. Each result has the policy, the rule, the resource, and a result of `pass`, `fail`, `warn`, `error` or `skip`. A report in a known format is easy to parse in a pipeline, to attach to a pull request, or to compare with the report of the live cluster.

```sh
kyverno apply policies/ --resource resources/pod-nolabel.yaml --policy-report
```

The CLI only prints the report. It does not create a `PolicyReport` object. Reports in the cluster are section 050.

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

## Putting it together in a pipeline

A typical pipeline step for a policies repository runs the CLI on every policy and a set of sample resources, with `--audit-warn` for policies that are still in `Audit`. A non-zero exit code stops the merge. After the merge, a deployment tool applies the policy to the cluster. Module 2 adds `kyverno test`, which stores the expected result next to the sample resources so that the pipeline checks them instead of you reading the output.
