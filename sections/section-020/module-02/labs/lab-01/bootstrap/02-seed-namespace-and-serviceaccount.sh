#!/usr/bin/env bash
set -eu

kubectl create namespace apps-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount ci-deployer -n apps-ns --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ci-deployer-pod-writer
  namespace: apps-ns
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deployer-pod-writer-binding
  namespace: apps-ns
subjects:
  - kind: ServiceAccount
    name: ci-deployer
    namespace: apps-ns
roleRef:
  kind: Role
  name: ci-deployer-pod-writer
  apiGroup: rbac.authorization.k8s.io
EOF

echo "apps-ns and ci-deployer (with Pod-create RBAC) ready."
