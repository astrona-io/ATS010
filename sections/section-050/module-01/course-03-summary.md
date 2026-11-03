# Summary

Reports are how Kyverno tells you what its policies found. You now know where to look, what each field means and how to turn a pile of reports into a short list of resources to fix.

## What you learned

Kyverno records verdicts in `PolicyReport` objects for namespaced resources and in `ClusterPolicyReport` objects for cluster-scoped resources. Both belong to the `wgpolicyk8s.io` API group, served as `v1alpha2` by Kyverno 1.13. The kind of the policy does not choose the report kind. The scope of the checked resource does.

Each report has a `summary` with counters for `pass`, `fail`, `warn`, `error` and `skip`, and a `results` list with the evidence. A result names the `policy`, the `rule`, the `result`, a `message`, and the resource, through a top-level `scope` or a `resources` list depending on version. Layout varies by version: Kyverno 1.13 generally writes one report per resource, older releases one per namespace, so a reliable query never depends on it.

`kubectl get polr,cpolr -A` gives the overview. `-o json` with `jq`, using `.items[] as $r | $r.results[]?`, answers real questions: which resources fail which rule, how many results per value, and what the failure message says. A fail is fixed by fixing the resource, never the report.

The key facts to remember are these:

- `PolicyReport` is namespaced, `ClusterPolicyReport` is cluster-scoped; a Namespace verdict is never in `policyreport`.
- Result values are `pass`, `fail`, `warn`, `error` and `skip`; an `error` is "could not evaluate", not a violation.
- `summary` counts results of one report, not resources and not the cluster.
- Read the resource name from `scope.name` first, then `resources[0].name`.
- An empty list right after applying a policy means "not yet", not "clean".

<!-- astrona:playground:destroy -->
