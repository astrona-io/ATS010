#!/usr/bin/env bash
# Reference solution for `astrona test`.
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

M="${HOME}/kyverno-lab/capstone"
cd "$M"

cat > policies/restrict-registry.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-registry
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - lab
      validate:
        message: "Images must come from ghcr.io/acme."
        pattern:
          spec:
            containers:
              - image: "ghcr.io/acme/*"
YAML

cat > tests/kyverno-test.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: restrict-registry
policies:
  - ../policies/restrict-registry.yaml
resources:
  - ../resources/pod-internal.yaml
  - ../resources/pod-external.yaml
results:
  - policy: restrict-registry
    rule: check-registry
    resources:
      - api
    kind: Pod
    namespace: lab
    result: pass
  - policy: restrict-registry
    rule: check-registry
    resources:
      - web
    kind: Pod
    namespace: lab
    result: fail
YAML

cat > ci/run.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."
kyverno test tests
SH
chmod +x ci/run.sh

kubectl apply -f policies/restrict-registry.yaml
