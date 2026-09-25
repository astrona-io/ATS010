#!/usr/bin/env bash
set -eu

kubectl create namespace checkout-live --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace reporting-live --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: old-reporter
  namespace: reporting-live
spec:
  replicas: 1
  selector:
    matchLabels:
      app: old-reporter
  template:
    metadata:
      labels:
        app: old-reporter
    spec:
      containers:
        - name: old-reporter
          image: nginx:alpine
EOF

kubectl -n reporting-live rollout status deployment/old-reporter --timeout=120s

echo "checkout-live, reporting-live, and pre-existing old-reporter Deployment ready."
