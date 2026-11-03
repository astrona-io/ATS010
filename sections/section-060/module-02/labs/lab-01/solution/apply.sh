#!/usr/bin/env bash
# Reference solution for `astrona test`: writes the two test files, the
# expected patched Pod and the CI script, and applies require-limits.
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

M="${HOME}/kyverno-lab/m2"
cd "$M"

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

cat > ci/run-policy-tests.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
cd "$(dirname "$0")/.."
kyverno test tests
SH
chmod +x ci/run-policy-tests.sh

kubectl apply -f policies/require-limits.yaml
