# Question

Solve this question on: `terminal`

The platform team wants to prove four policies on files before any of them reaches the cluster. The working directory is `$HOME/kyverno-lab/m1`. It already holds five Pod manifests in `resources/`: `pod-good.yaml` (`web-good`), `pod-nolabel.yaml` (`web-nolabel`), `pod-latest.yaml` (`web-latest`), `pod-prod.yaml` (`web-prod`) and `pod-dev.yaml` (`web-dev`). Every manifest has `namespace: lab`. The `kyverno` command is installed. Do not edit the files in `resources/`.

1. In `policies/require-team-label.yaml`, write a `ClusterPolicy` named `require-team-label` with `validationFailureAction: Enforce` and one validate rule named `check-team`. The rule requires a non-empty label `team` on every Pod in the namespace `lab`. Prove that `kyverno apply` exits 0 for `web-good` and non-zero for `web-nolabel`.
2. In `policies/disallow-latest-tag.yaml`, write a `ClusterPolicy` named `disallow-latest-tag` with `validationFailureAction: Audit` and one validate rule named `no-latest` that rejects any container image that ends in `:latest`. Prove that `web-latest` fails, and that the same command exits 0 when you add `--audit-warn`.
3. In `policies/require-env-label.yaml`, write a `ClusterPolicy` named `require-env-label` with a validate rule named `check-env`. The rule requires the label `env` to equal the variable `{{ allowedEnv }}`. Put the value in `values/values.yaml` (kind `Values`) and set `allowedEnv` to `prod`. Prove that `web-prod` passes and `web-dev` fails when you pass `--values-file`.
4. In `policies/add-managed-by-label.yaml`, write a `ClusterPolicy` named `add-managed-by-label` with a mutate rule named `add-label` that adds the label `managed-by: kyverno` to every Pod. Run `kyverno apply` on `web-good` and save the mutated Pod to `out/patched.yaml` with the `-o` flag.
5. A Pod named `legacy` already runs in the namespace `lab`. Use `kyverno apply` with `--cluster` and `require-team-label` to scan the cluster, and confirm that `legacy` is reported.
6. Apply `require-team-label` to the cluster with `kubectl`, wait until it is Ready, and confirm that the cluster rejects `web-nolabel` and admits `web-good` (use `--dry-run=server`).

The values file starts like this:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Values
policies:
  - name: require-env-label
    rules:
      - name: check-env
        values:
          allowedEnv: prod
```
