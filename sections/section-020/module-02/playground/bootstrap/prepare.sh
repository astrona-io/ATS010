#!/usr/bin/env bash
# Installs Kyverno and seeds the Module 2 playground. Runs once at start.
set -eu

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=180s
done

echo "Seeding apps-ns, service accounts and Pods..."
kubectl create namespace apps-ns --dry-run=client -o yaml | kubectl apply -f -
for sa in ci-deployer auditor ops-admin; do
  kubectl create serviceaccount "$sa" -n apps-ns --dry-run=client -o yaml | kubectl apply -f -
done

cat <<'YAML' | kubectl apply -f -
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
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: auditor-view
  namespace: apps-ns
subjects:
  - kind: ServiceAccount
    name: auditor
    namespace: apps-ns
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ops-admin-admin
  namespace: apps-ns
subjects:
  - kind: ServiceAccount
    name: ops-admin
    namespace: apps-ns
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: web-frontend
  namespace: apps-ns
  labels: {tier: frontend, app: shop}
spec:
  containers:
    - name: web
      image: ghcr.io/stefanprodan/podinfo:6.15.0
---
apiVersion: v1
kind: Pod
metadata:
  name: web-backend
  namespace: apps-ns
  labels: {tier: backend, app: shop}
spec:
  containers:
    - name: web
      image: ghcr.io/stefanprodan/podinfo:6.15.0
YAML

kubectl -n apps-ns wait --for=condition=Ready pod/web-frontend pod/web-backend --timeout=180s

echo "Playground ready: Kyverno ${KYVERNO_VERSION}, no policies."
