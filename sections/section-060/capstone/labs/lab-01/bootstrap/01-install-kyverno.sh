#!/usr/bin/env bash
# Installs Kyverno v1.13.2 into the kind cluster and waits for its four controllers.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=240s
done

echo "Kyverno is ready."
