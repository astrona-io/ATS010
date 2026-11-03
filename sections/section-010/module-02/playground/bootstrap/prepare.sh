#!/usr/bin/env bash
# Environment prep for the "Applying Beyond Admission" playground
# (`ats-010-playground-010-02`).
#
# Environment preparation only - there is no task and no grading. This script:
#   1. installs Kyverno v1.13.2 from its release manifest,
#   2. waits until the four controllers are ready and the webhooks exist,
#   3. creates the namespace `background-ns` with the Deployments
#      `legacy-worker` and `report-worker`, both without resource limits.
# No policy is created and PolicyException support stays disabled.
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

echo "[playground] Seeding background-ns..."
kubectl create namespace background-ns --dry-run=client -o yaml | kubectl apply -f -
for name in legacy-worker report-worker; do
  kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  namespace: background-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${name}
  template:
    metadata:
      labels:
        app: ${name}
    spec:
      containers:
        - name: ${name}
          image: nginx:alpine
YAML
done
for name in legacy-worker report-worker; do
  kubectl -n background-ns rollout status "deployment/${name}" --timeout=180s
done
echo "[playground] Ready."
