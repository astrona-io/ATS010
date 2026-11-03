#!/usr/bin/env bash
# Environment prep for the "Applying Validate And Mutate Policies" playground
# (`ats-010-playground-040-01`).
#
# Environment preparation only - there is no task and no grading. This script:
#   1. installs Kyverno v1.13.2 from its release manifest,
#   2. waits until the four Kyverno controllers are ready and the webhook
#      configurations exist,
#   3. creates the namespaces `starfleet` and `outpost` and a ConfigMap.
# No ClusterPolicy is created.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done

# The admission controller registers the webhook configurations after it starts.
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1 \
     && kubectl get mutatingwebhookconfiguration kyverno-resource-mutating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[playground] Creating the sandbox namespaces..."
kubectl create namespace starfleet
kubectl create namespace outpost
kubectl create configmap crew-notes -n starfleet --from-literal=motto="steady as she goes"
echo "[playground] Ready."
