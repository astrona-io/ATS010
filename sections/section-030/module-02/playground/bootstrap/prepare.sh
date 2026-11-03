#!/usr/bin/env bash
# Starting state for the Module 2 playground. Environment only: installs
# Kyverno v1.13.2, lets the background controller manage the kinds the
# practice tasks use, and creates namespaces and Deployments that exist
# BEFORE any policy does. It creates no ClusterPolicy.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for d in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${d}" --timeout=300s
done
kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s

# Generate and mutate-existing rules run in the background controller, which
# needs rights on what they create or patch. This role is aggregated into it.
kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ats010-background-controller-extra
  labels:
    rbac.kyverno.io/aggregate-to-background-controller: "true"
rules:
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["create", "get", "list", "update", "patch", "delete", "watch"]
  - apiGroups: [""]
    resources: ["configmaps", "namespaces"]
    verbs: ["create", "get", "list", "update", "patch", "delete", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "update", "patch", "watch"]
YAML

for ns in team-a team-b team-c; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
for ns in team-a team-b; do
  kubectl create deployment web --image=nginx:alpine -n "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "$ns" rollout status deployment/web --timeout=180s
done
echo "[playground] Ready."
