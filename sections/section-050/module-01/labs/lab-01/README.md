---
estimated_duration: 20m
---

# Lab: Read PolicyReports and ClusterPolicyReports

UNTESTED - built from static checks only; not yet booted.

Graded lab for the report-reading module. Two `Audit` policies have already run against seeded ConfigMaps and Namespaces. The learner reads the `PolicyReport` and `ClusterPolicyReport` objects and records the findings in a ConfigMap, without changing anything. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-010-lab-013
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine running the checks needs `kubectl` and `jq`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-reports-present.sh` | Polls up to 240s each: `require-owner-label` shows 3 pass and 2 fail in `fleet-reports`, `require-namespace-team` shows 1 pass and 1 fail in the `ClusterPolicyReport` |
| `validate-resources-untouched.sh` | The five ConfigMaps exist, both policies are still `Audit`, the violators are still violators |
| `validate-findings-failing-configmaps.sh` | `report-findings` key `failing-configmaps` equals the failing set computed from the reports |
| `validate-findings-counts.sh` | `pass-count` and `fail-count` equal the result counts computed from the reports |
| `validate-findings-failing-namespaces.sh` | `failing-namespaces` equals the failing set in the `ClusterPolicyReport` |

The expected values are computed from the live reports, not hard-coded, and the scripts read the resource name from `scope.name` with a fallback to `resources[0].name`, so they tolerate both report layouts. Open assumption: Kyverno 1.13.2 produces results for ConfigMaps in the seeded namespace (not excluded by its default resource filters).
