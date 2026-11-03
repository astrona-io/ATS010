#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: ops-require-limits
spec:
  validationFailureAction: Enforce
  failurePolicy: Fail
  webhookTimeoutSeconds: 8
  background: true
  rules:
    - name: check-resource-limits
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - ops-prod
      validate:
        message: "Every container in ops-prod must set CPU and memory resource limits."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    cpu: "?*"
                    memory: "?*"
YAML
kubectl wait --for=condition=Ready clusterpolicy/ops-require-limits --timeout=90s

for i in $(seq 1 30); do
  kubectl run no-limits-pod --image=nginx:alpine -n ops-prod >/dev/null 2>&1 || break
  kubectl delete pod no-limits-pod -n ops-prod --ignore-not-found >/dev/null 2>&1
  sleep 2
done
kubectl run has-limits-pod --image=nginx:alpine -n ops-prod \
  --overrides='{"spec":{"containers":[{"name":"has-limits-pod","image":"nginx:alpine","resources":{"limits":{"cpu":"250m","memory":"128Mi"}}}]}}'

kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-audit-configmap
spec:
  generateExisting: true
  rules:
    - name: clone-audit-config
      match:
        any:
        - resources:
            kinds:
              - Namespace
      exclude:
        any:
        - resources:
            namespaces:
              - kube-system
              - kyverno
              - kube-node-lease
              - kube-public
              - local-path-storage
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: audit-config
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          data:
            audit-level: "standard"
YAML
kubectl wait --for=condition=Ready clusterpolicy/clone-audit-configmap --timeout=90s

kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: tier-cost-labels
spec:
  applyRules: "One"
  rules:
    - name: gold-tier-override
      match:
        any:
        - resources:
            kinds:
              - Namespace
            selector:
              matchLabels:
                tier: gold
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: premium
    - name: standard-tier-default
      match:
        any:
        - resources:
            kinds:
              - Namespace
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: standard
YAML
kubectl wait --for=condition=Ready clusterpolicy/tier-cost-labels --timeout=90s
kubectl label namespace ops-prod tier=gold --overwrite
