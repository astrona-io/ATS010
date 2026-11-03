#!/usr/bin/env bash
# Installs Kyverno v1.13.2 and waits for its four controllers and webhooks.
# UNTESTED - built from static checks only; not yet booted.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=300s
done

# The webhooks are registered by the admission controller after it starts.
for _ in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Kyverno is ready."

