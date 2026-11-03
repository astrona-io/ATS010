#!/usr/bin/env bash
# Seeds the Module 2 working directory $HOME/kyverno-lab/m2 with two policies
# and three Pod manifests. The learner writes the tests, the expected mutated
# file and the CI script.
set -euo pipefail

M="${HOME}/kyverno-lab/m2"
mkdir -p "${M}/policies" "${M}/resources" "${M}/tests/limits" "${M}/tests/labels" "${M}/ci"

cat > "${M}/policies/require-limits.yaml" <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-limits
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Every container must set resources.limits.memory."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
YAML

cat > "${M}/policies/add-managed-by-label.yaml" <<'YAML'
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

cat > "${M}/resources/pod-with-limits.yaml" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: web-ok
  labels:
    app: web
spec:
  containers:
    - name: app
      image: nginx:1.27
      resources:
        limits:
          memory: 128Mi
YAML

cat > "${M}/resources/pod-no-limits.yaml" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: web-nolimits
  labels:
    app: web
spec:
  containers:
    - name: app
      image: nginx:1.27
YAML

cat > "${M}/resources/pod-unlabelled.yaml" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  containers:
    - name: app
      image: busybox:1.36
      resources:
        limits:
          memory: 64Mi
YAML

echo "Seeded ${M}."
