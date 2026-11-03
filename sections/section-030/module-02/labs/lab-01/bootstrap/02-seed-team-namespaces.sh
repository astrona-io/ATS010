#!/usr/bin/env bash
set -eu

# Generate rules run in Kyverno's background controller, which needs rights on
# the kinds they create. This ClusterRole is aggregated into it.
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
YAML

for ns in team-a team-b team-c; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "team-a, team-b, and team-c ready (pre-existing, before any policy is applied)."
