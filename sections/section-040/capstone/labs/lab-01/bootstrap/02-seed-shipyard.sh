#!/usr/bin/env bash
# Starting state: the namespace `shipyard` (labelled onboarding=true) with two
# ConfigMaps, one of them marked ttl-expired=true. No policy and no extra
# Kyverno RBAC exist.
set -eu

kubectl create namespace shipyard
kubectl label namespace shipyard onboarding=true
kubectl create configmap shipyard-notes -n shipyard --from-literal=note=current
kubectl create configmap shipyard-old -n shipyard --from-literal=note=stale
kubectl label configmap shipyard-old -n shipyard ttl-expired=true
echo "Shipyard namespace seeded."
