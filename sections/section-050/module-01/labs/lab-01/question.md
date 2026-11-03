# Question

Solve this question on: `terminal`

Kyverno is installed, and two `Audit` policies already ran. `require-owner-label` checks ConfigMaps labelled `app=fleet` in the `fleet-reports` namespace for an `owner` label. `require-namespace-team` checks Namespaces labelled `demo=reports` for a `team` label. Reports may take a minute or two to appear after the cluster starts.

The platform team wants a written record of what the reports say, and wants it without changing anything in the cluster. Read the reports and record the findings:

1. Find which ConfigMaps in `fleet-reports` fail `require-owner-label`.

2. Count the `pass` results and the `fail` results of `require-owner-label` in the `fleet-reports` reports. Count results, not resources and not the `summary` of one report.

3. Find which Namespaces fail `require-namespace-team`. These are cluster-scoped resources, so their results are in a different report kind.

4. Create a ConfigMap named `report-findings` in the `fleet-reports` namespace with exactly these keys:

   | Key | Value |
   | --- | --- |
   | `failing-configmaps` | Names of the failing ConfigMaps, sorted, comma-separated, no spaces |
   | `pass-count` | Number of `pass` results of `require-owner-label` |
   | `fail-count` | Number of `fail` results of `require-owner-label` |
   | `failing-namespaces` | Names of the failing Namespaces, sorted, comma-separated, no spaces |

Do not label, edit, delete or enforce anything else. The policies must stay in `Audit` and the violators must stay violators. `kubectl` already points at the cluster as the cluster administrator, and `jq` is available on your machine.
