# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running after a failed check.

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-02/labs/lab-01
cd $HOME/kyverno-lab/m2
```

## Step 1: Test the validate policy

A test lists the policy files, the resource files and one result per policy, rule and resource. Paths are relative to the test file, so `tests/limits/` reaches `policies/` with `../../`.

```sh
cat > tests/limits/kyverno-test.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: require-limits
policies:
  - ../../policies/require-limits.yaml
resources:
  - ../../resources/pod-with-limits.yaml
  - ../../resources/pod-no-limits.yaml
results:
  - policy: require-limits
    rule: check-limits
    resources:
      - web-ok
    kind: Pod
    result: pass
  - policy: require-limits
    rule: check-limits
    resources:
      - web-nolimits
    kind: Pod
    result: fail
YAML
kyverno test tests/limits --detailed-results
```

The CLI prints one line per result and the command exits 0. A result `fail` here means: the policy is expected to fail this resource, and the test passes because it does. Submit with `astrona submit --keep`.

## Step 2: Test the mutate policy

For a mutate rule the test compares the mutated resource with an expected file.

```sh
cat > tests/labels/kyverno-test.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: add-managed-by-label
policies:
  - ../../policies/add-managed-by-label.yaml
resources:
  - ../../resources/pod-unlabelled.yaml
results:
  - policy: add-managed-by-label
    rule: add-label
    resources:
      - worker
    kind: Pod
    patchedResources: patched.yaml
    result: pass
YAML
cat > tests/labels/patched.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
    managed-by: kyverno
spec:
  containers:
    - name: app
      image: busybox:1.36
      resources:
        limits:
          memory: 64Mi
YAML
kyverno test tests/labels --detailed-results
```

If the test fails, run `kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-unlabelled.yaml -o /tmp/p.yaml` and compare `/tmp/p.yaml` with your expected file.

## Step 3: The CI script

```sh
cat > ci/run-policy-tests.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."
kyverno test tests
SH
chmod +x ci/run-policy-tests.sh
cd / && $HOME/kyverno-lab/m2/ci/run-policy-tests.sh; echo "exit=$?"; cd $HOME/kyverno-lab/m2
```

`kyverno test tests` finds every `kyverno-test.yaml` under `tests/` and runs them all. The script exits 0 now. When one result differs, `kyverno test` exits non-zero and the CI job fails.

## Step 4: Apply the tested policy

```sh
kubectl apply -f policies/require-limits.yaml
kubectl get clusterpolicy require-limits
kubectl apply --dry-run=server -f resources/pod-no-limits.yaml
kubectl apply --dry-run=server -f resources/pod-with-limits.yaml
```

Wait for the policy to be Ready. The `web-nolimits` request is rejected with the policy message and the `web-ok` request is accepted. Submit one last time with `astrona submit`.
