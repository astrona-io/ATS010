#!/usr/bin/env bash
# Starting state: the namespace `starfleet`, a protected ConfigMap and a plain one.
# No policy exists.
set -eu

kubectl create namespace starfleet
kubectl create configmap fleet-registry -n starfleet --from-literal=owner=platform
kubectl label configmap fleet-registry -n starfleet protected=true
kubectl create configmap scratch-notes -n starfleet --from-literal=note=temporary
echo "Starfleet namespace seeded."
