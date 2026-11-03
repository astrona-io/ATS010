#!/usr/bin/env bash
# Environment prep for the "Applying Generate And Cleanup Policies" playground
# (`ats-010-playground-040-02`).
#
# Environment preparation only - there is no task and no grading. This script:
#   1. installs Kyverno v1.13.2 from its release manifest,
#   2. waits until the four Kyverno controllers are ready and the webhook
#      configurations exist,
#   3. creates `fleet-system` (with the ConfigMap fleet-banner) and `scratch`
#      (with two ConfigMaps, one labelled expired=true).
# No ClusterPolicy, no cleanup policy and no extra Kyverno RBAC are created.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done

for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1 \
     && kubectl get mutatingwebhookconfiguration kyverno-resource-mutating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[playground] Creating the sandbox namespaces and ConfigMaps..."
kubectl create namespace fleet-system
kubectl create configmap fleet-banner -n fleet-system --from-literal=message="Welcome aboard"
kubectl create namespace scratch
kubectl create configmap old-report -n scratch --from-literal=data=stale
kubectl label configmap old-report -n scratch expired=true
kubectl create configmap keep-report -n scratch --from-literal=data=current
kubectl label configmap keep-report -n scratch expired=false
echo "[playground] Ready."
