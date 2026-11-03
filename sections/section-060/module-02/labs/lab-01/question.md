# Question

Solve this question on: `terminal`

The platform team keeps its policies in git and wants every change checked by `kyverno test` in CI. The working directory is `$HOME/kyverno-lab/m2`. It holds two policies in `policies/` (`require-limits` with the rule `check-limits`, and `add-managed-by-label` with the rule `add-label`) and three Pod manifests in `resources/`: `web-ok` (has a memory limit), `web-nolimits` (has none) and `worker` (has no `managed-by` label). Do not edit the files in `policies/` or `resources/`.

1. Create `tests/limits/kyverno-test.yaml` (kind `Test`). It tests `require-limits` against `pod-with-limits.yaml` and `pod-no-limits.yaml`. Expect `pass` for `web-ok` and `fail` for `web-nolimits`, both for the rule `check-limits`. `kyverno test tests/limits` must succeed.
2. Create `tests/labels/kyverno-test.yaml`. It tests the mutate rule `add-label` of `add-managed-by-label` against `pod-unlabelled.yaml`. The result for `worker` is `pass` and names `patched.yaml` in `patchedResources`. Write the expected Pod to `tests/labels/patched.yaml`: the `worker` Pod with the extra label `managed-by: kyverno`. `kyverno test tests/labels` must succeed.
3. Create the script `ci/run-policy-tests.sh`. It stops on the first error, works from any current directory, and runs `kyverno test tests`. Make it executable and run it.
4. Apply `require-limits` to the cluster with `kubectl` and wait until it is Ready. Confirm that the cluster rejects `web-nolimits` and admits `web-ok` (use `--dry-run=server`).

A test file has this shape. Paths are relative to the test file:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: <name>
policies:
  - <path to policy>
resources:
  - <path to resource>
results:
  - policy: <policy name>
    rule: <rule name>
    resources:
      - <metadata.name of the resource>
    kind: Pod
    result: pass
```
