#!/usr/bin/env bash
set -eu

kubectl create namespace background-ns --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-worker
  namespace: background-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy-worker
  template:
    metadata:
      labels:
        app: legacy-worker
    spec:
      containers:
        - name: legacy-worker
          image: nginx:alpine
EOF

kubectl -n background-ns rollout status deployment/legacy-worker --timeout=120s

echo "background-ns namespace and pre-existing legacy-worker Deployment ready."
