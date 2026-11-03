#!/usr/bin/env bash
# Starting state: the clone source in fleet-system and two ConfigMaps in scratch.
# No policy and no extra Kyverno RBAC exist.
set -eu

kubectl create namespace fleet-system
kubectl create configmap fleet-banner -n fleet-system --from-literal=message="Welcome aboard"

kubectl create namespace scratch
kubectl create configmap old-report -n scratch --from-literal=data=stale
kubectl label configmap old-report -n scratch expired=true
kubectl create configmap keep-report -n scratch --from-literal=data=current
kubectl label configmap keep-report -n scratch expired=false
echo "Fleet namespaces seeded."
