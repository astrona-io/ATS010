#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/policy-audit.yaml"
kubectl wait --for=condition=Ready clusterpolicy/require-resource-limits --timeout=120s || true
sleep 10

# Admitted under Audit.
for _ in $(seq 1 10); do
  kubectl run no-limits-pod --image=nginx:alpine -n platform-ns && break
  sleep 3
done
sleep 10

kubectl apply -f "$DIR/policy-enforce.yaml"
kubectl wait --for=condition=Ready clusterpolicy/require-resource-limits --timeout=120s || true
sleep 10

# Expected to be rejected by Enforce.
kubectl run no-limits-pod-2 --image=nginx:alpine -n platform-ns || true

kubectl run has-limits-pod --image=nginx:alpine -n platform-ns \
  --overrides='{"spec":{"containers":[{"name":"has-limits-pod","image":"nginx:alpine","resources":{"limits":{"cpu":"100m","memory":"64Mi"}}}]}}'
echo "[solution] Applied."
