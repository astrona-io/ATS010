# Question

Solve this question on: `terminal`

The `rollout-lab` namespace holds four ConfigMaps labelled `app=fleet`: `ok-1` has an `owner` label, while `bad-1`, `bad-2` and `bad-3` do not. The `ClusterPolicy` `require-owner-label` checks exactly these ConfigMaps and runs in `Audit`, so it admits everything and reports. Reports may take a minute or two to appear after the cluster starts.

The team wants to switch `require-owner-label` to `Enforce`, but only after the reports show the namespace is clean. Use the reports as the gate:

1. Read the reports of `require-owner-label` in `rollout-lab` and count the `fail` results.

2. Record the gate numbers in a ConfigMap named `gate-record` in `rollout-lab` with two keys: `violators-found` holds the number of `fail` results you saw before you changed anything, and `fail-at-flip` holds the number of `fail` results the reports show when you flip the policy.

3. Remediate the violators. `bad-1` and `bad-2` belong to a team: give each an `owner` label (any non-empty value). `bad-3` is abandoned: delete it. Do not touch `ok-1`.

4. Wait until the reports are clean. Clean means no `fail` result, exactly three `pass` results, and no result left for the deleted `bad-3`.

5. Only then, change `validationFailureAction` of `require-owner-label` to `Enforce`.

6. Prove it works: a ConfigMap in `rollout-lab` with `app=fleet` and no `owner` label must be rejected, and one with `app=fleet` and `owner=ops` must be admitted. Use a server-side dry run, so that nothing is created.

`kubectl` already points at the cluster as the cluster administrator, and `jq` is available on your machine.
