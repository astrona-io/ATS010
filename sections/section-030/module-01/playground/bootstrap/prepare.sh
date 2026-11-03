#!/usr/bin/env bash
# Starting state for the Module 1 playground. Environment only: installs
# Kyverno v1.13.2, waits until it is ready, and creates two empty namespaces.
# It creates no ClusterPolicy.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for d in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${d}" --timeout=300s
done
kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s

for ns in critical-ns lenient-ns sandbox; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
echo "[playground] Ready."
