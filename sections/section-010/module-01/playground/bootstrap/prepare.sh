#!/usr/bin/env bash
# Environment prep for the "Getting a Policy Live" playground
# (`ats-010-playground-010-01`).
#
# Environment preparation only - there is no task and no grading. This script:
#   1. installs Kyverno v1.13.2 from its release manifest,
#   2. waits until the four controllers are ready and the webhooks exist,
#   3. creates the namespaces `payments` and `platform-ns` and the Deployment
#      `ledger` in `payments`.
# No ClusterPolicy, Policy or PolicyException is created.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done

# The admission controller registers the webhook configurations after it starts.
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1 \
    && kubectl get validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[playground] Seeding namespaces and the ledger Deployment..."
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace platform-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  namespace: payments
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
    spec:
      containers:
        - name: ledger
          image: nginx:alpine
YAML
kubectl -n payments rollout status deployment/ledger --timeout=180s
echo "[playground] Ready."
