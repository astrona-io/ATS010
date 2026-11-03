#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-default-netpol
spec:
  generateExisting: true
  rules:
    - name: clone-netpol-to-namespace
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
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
YAML
kubectl wait --for=condition=Ready clusterpolicy/clone-default-netpol --timeout=90s

kubectl create namespace team-d
kubectl apply -f - <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: label-namespace-by-tier
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
kubectl wait --for=condition=Ready clusterpolicy/label-namespace-by-tier --timeout=90s

kubectl label namespace team-a tier=gold --overwrite
kubectl create namespace team-e
