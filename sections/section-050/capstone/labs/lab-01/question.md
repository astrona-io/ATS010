# Question

Solve this question on: `terminal`

Two namespaces, `fleet-a` and `fleet-b`, hold ConfigMaps labelled `app=fleet`: `a-ok` and `b-ok` have an `owner` label, while `a-bad`, `b-bad` and `b-stale` do not. Both namespaces carry the label `demo=reports`; `fleet-a` also has a `team` label and `fleet-b` does not. Two `Audit` policies already ran:

- `require-owner-label` checks ConfigMaps labelled `app=fleet` in `fleet-a` and `fleet-b` for an `owner` label (results in `PolicyReport` objects in each namespace).
- `require-namespace-team` checks Namespaces labelled `demo=reports` for a `team` label (results in the `ClusterPolicyReport`).

Reports may take a minute or two to appear after the cluster starts. Move both policies safely from `Audit` to `Enforce`:

1. Before you change anything, read the reports. Create a ConfigMap named `capstone-findings` in `fleet-a` with two keys: `failing-configmaps` lists the ConfigMaps that fail `require-owner-label` as `namespace/name`, sorted, comma-separated, no spaces; `failing-namespaces` lists the Namespaces that fail `require-namespace-team`, sorted, comma-separated, no spaces.

2. Remediate every violator. `a-bad` and `b-bad` are owned by a team: give each an `owner` label (any non-empty value). `b-stale` is abandoned: delete it. Give the Namespace `fleet-b` a `team` label (any non-empty value). Do not touch `a-ok`, `b-ok` or `fleet-a`.

3. Wait until the reports are clean on both report kinds: no `fail` result, and the passes present (two ConfigMap passes in each namespace, and two Namespace passes), with nothing left for `b-stale`.

4. Only then, change `validationFailureAction` to `Enforce` on both policies.

5. Prove it works with server-side dry runs: in `fleet-a`, a ConfigMap with `app=fleet` and no `owner` is rejected and one with `app=fleet` and `owner=ops` is admitted; a new Namespace with `demo=reports` and no `team` label is rejected and one with `demo=reports` and `team=ops` is admitted.

`kubectl` already points at the cluster as the cluster administrator, and `jq` is available on your machine.
