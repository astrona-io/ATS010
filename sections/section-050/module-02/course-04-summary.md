# Summary

Reports are a pipeline, not a log. Two sources feed them, results age with their resource and policy, and the same data lets you decide when an `Audit` policy is ready to enforce.

## What you learned

Results come from the admission webhook, when a matching request is created or updated, and from the background scan run by the reports controller, which checks resources that admission never saw. The scan runs when a policy or resource changes and on a periodic interval, `--backgroundScanInterval`, default one hour. Both sources write internal ephemeral reports first, which the reports controller aggregates into `PolicyReport` and `ClusterPolicyReport`. A short delay between a change and its report is normal.

A result lives only as long as both its resource and its policy. Fixing a resource turns a `fail` into a `pass`, deleting the resource or the policy removes the result, and changing the policy triggers a fresh scan. `Enforce` still produces results: `pass` for admitted resources and `fail` for older violators found by the scan, but a request it blocked leaves no report. A `skip` usually means a `PolicyException` or a false precondition, while unselected resources produce no result.

Reports are the go or no-go signal before `Enforce`. Wait for reports, require both zero `fail` and at least one `pass`, fix or remove violators, wait again, flip the policy, then prove both a rejection and an admission with a server-side dry run. `emitWarning` surfaces `Audit` failures to the client, and Kyverno metrics show trends. The key facts to remember are these:

- Admission results are immediate but aggregated asynchronously; scans catch what admission missed.
- Reports describe existing resources, not rejected requests.
- Empty reports can mean "nothing matched yet"; ask for evidence of passes.
- Fix the resource, never the report; wait before you conclude.

<!-- astrona:playground:destroy -->
