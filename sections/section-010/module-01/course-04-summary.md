# Summary

A policy is a normal Kubernetes resource. You apply it with `kubectl apply`, and the cluster only enforces what you last applied. A server-side dry run (`kubectl apply --dry-run=server`) and `kubectl diff` let you check a change before it is stored. Kyverno validates the policy object itself, so a malformed policy is refused at apply time and never becomes live.

A `ClusterPolicy` can match resources in any namespace and cluster-scoped kinds. A `Policy` lives in one namespace and only checks resources in that namespace. Both use the same rule syntax, and both are removed immediately by `kubectl delete`.

`validationFailureAction` decides what a failing resource gets at admission time. `Enforce` rejects the request and the resource is not created. `Audit` admits it and records the violation in a report. Neither value touches resources that already exist. Teams ship a new policy as `Audit`, read the reports, fix the rule or the workloads, and then move to `Enforce`. `validationFailureActionOverrides` lets one policy enforce in some namespaces while the rest stay in `Audit`.

Status, reports and events show what a policy did. `kubectl get clusterpolicy` shows the `ADMISSION`, `BACKGROUND` and `READY` columns, and `kubectl describe` adds the status message and events. `PolicyReport` and `ClusterPolicyReport` objects hold `pass`, `fail`, `warn`, `error` and `skip` results. The key facts to remember are these:

- `--dry-run=client` never contacts Kyverno; `--dry-run=server` does.
- `kubectl diff` exits with 1 when the cluster differs from the file.
- A `Policy` is namespaced and cannot match cluster-scoped kinds.
- `Enforce` blocks new requests only; `Audit` admits and records.
- A report lives in the namespace of the resource it describes.

<!-- astrona:playground:destroy -->
