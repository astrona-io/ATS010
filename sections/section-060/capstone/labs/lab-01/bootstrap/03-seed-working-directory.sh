#!/usr/bin/env bash
# Seeds $HOME/kyverno-lab/capstone with two Pod manifests and creates the
# namespace `lab` with one existing Pod (legacy-external) that uses an image
# from a registry other than ghcr.io/acme.
set -euo pipefail

M="${HOME}/kyverno-lab/capstone"
mkdir -p "${M}/policies" "${M}/resources" "${M}/tests" "${M}/ci"

cat > "${M}/resources/pod-internal.yaml" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: api
  namespace: lab
  labels:
    app: api
spec:
  containers:
    - name: app
      image: ghcr.io/acme/api:1.2.0
YAML

cat > "${M}/resources/pod-external.yaml" <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: lab
  labels:
    app: web
spec:
  containers:
    - name: app
      image: docker.io/library/nginx:1.27
YAML

kubectl create namespace lab --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'POD'
apiVersion: v1
kind: Pod
metadata:
  name: legacy-external
  namespace: lab
  labels:
    app: legacy
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
POD

echo "Seeded ${M}."
