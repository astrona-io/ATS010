#!/usr/bin/env bash
set -eu

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=300s
done

# The admission controller registers its webhook configurations after it
# starts. Wait for them so the first `kubectl apply` of a policy is not racing
# the registration.
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1 \
    && kubectl get validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Kyverno is ready."
