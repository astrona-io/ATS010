#!/usr/bin/env bash
set -eu

kubectl create namespace store-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace store-dev --dry-run=client -o yaml | kubectl apply -f -

kubectl label namespace store-prod env=prod --overwrite
kubectl label namespace store-dev env=dev --overwrite

kubectl create serviceaccount release-bot -n store-prod --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: release-bot-deployment-writer
  namespace: store-prod
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: release-bot-deployment-writer-binding
  namespace: store-prod
subjects:
  - kind: ServiceAccount
    name: release-bot
    namespace: store-prod
roleRef:
  kind: Role
  name: release-bot-deployment-writer
  apiGroup: rbac.authorization.k8s.io
EOF

echo "store-prod (env=prod), store-dev (env=dev), and release-bot (with Deployment-write RBAC) ready."
