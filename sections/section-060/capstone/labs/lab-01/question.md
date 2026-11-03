# Question

Solve this question on: `terminal`

Your team allows container images only from `ghcr.io/acme`. You must ship this as a policy with a test that runs in CI. The working directory is `$HOME/kyverno-lab/capstone`. It holds two Pod manifests in `resources/`: `pod-internal.yaml` (Pod `api`, image `ghcr.io/acme/api:1.2.0`) and `pod-external.yaml` (Pod `web`, image `docker.io/library/nginx:1.27`). Both are in the namespace `lab`. A Pod named `legacy-external` already runs in `lab`. Do not edit the files in `resources/`.

1. Write `policies/restrict-registry.yaml`: a `ClusterPolicy` named `restrict-registry` with `validationFailureAction: Enforce` and one validate rule named `check-registry`. The rule applies to Pods in the namespace `lab` and requires every container image to start with `ghcr.io/acme/`.
2. Prove it offline: `kyverno apply` exits 0 for `api` and non-zero for `web`.
3. Write `tests/kyverno-test.yaml` with two results for the rule `check-registry`: `pass` for `api` and `fail` for `web`. `kyverno test tests` must succeed.
4. Write the CI script `ci/run.sh`. It stops on the first error, works from any directory, and runs `kyverno test tests`. Make it executable.
5. Scan the existing cluster with `kyverno apply` and `--cluster`. Confirm that `legacy-external` is reported.
6. Before you apply the policy, think about rollout. Run `kyverno apply` with the policy switched to `Audit` in a copy, and with and without `--audit-warn`, and note how the exit code changes. Keep `Enforce` in your real policy file.
7. Apply `restrict-registry` to the cluster, wait until it is Ready, and confirm with `--dry-run=server` that `web` is rejected and `api` is admitted.
