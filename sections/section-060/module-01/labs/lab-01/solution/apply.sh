#!/usr/bin/env bash
# Reference solution for `astrona test`: writes the policy files and the values
# file, saves the mutated output, and applies the proven policy to the cluster.
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

M="${HOME}/kyverno-lab/m1"
cd "$M"

cat > policies/require-team-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - lab
      validate:
        message: "The label 'team' is required."
        pattern:
          metadata:
            labels:
              team: "?*"
YAML

cat > policies/disallow-latest-tag.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Audit
  rules:
    - name: no-latest
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Do not use the image tag 'latest'."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
YAML

cat > policies/add-managed-by-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-managed-by-label
spec:
  rules:
    - name: add-label
      match:
        any:
          - resources:
              kinds:
                - Pod
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              managed-by: kyverno
YAML

cat > policies/require-env-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-env-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-env
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "The label 'env' must be {{ allowedEnv }}."
        pattern:
          metadata:
            labels:
              env: "{{ allowedEnv }}"
YAML

cat > values/values.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Values
policies:
  - name: require-env-label
    rules:
      - name: check-env
        values:
          allowedEnv: prod
YAML

kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-good.yaml -o out/patched.yaml || true
kubectl apply -f policies/require-team-label.yaml
