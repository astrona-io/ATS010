#!/usr/bin/env bash
# Installs Kyverno and seeds the playground. Runs once at start.
set -eu

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

echo "Seeding namespaces and ConfigMaps..."
for ns in shop-prod shop-dev shop-stage; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
kubectl label namespace shop-prod env=prod --overwrite
kubectl label namespace shop-dev env=dev --overwrite
kubectl label namespace shop-stage env=staging --overwrite

for cm in app-secrets db-secrets credentials prod-settings canary-settings; do
  kubectl create configmap "$cm" -n shop-prod --from-literal=note=seed --dry-run=client -o yaml | kubectl apply -f -
done
kubectl create configmap app-settings -n shop-dev --from-literal=note=seed --dry-run=client -o yaml | kubectl apply -f -

echo "Playground ready: Kyverno ${KYVERNO_VERSION}, no policies."
