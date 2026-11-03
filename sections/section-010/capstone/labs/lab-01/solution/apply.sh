#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/checkout-policy.yaml"
kubectl apply -f "$DIR/reporting-policy.yaml"
kubectl wait --for=condition=Ready clusterpolicy/checkout-require-limits --timeout=120s || true
kubectl wait --for=condition=Ready clusterpolicy/reporting-audit-limits --timeout=120s || true
sleep 20

# Expected to be rejected by Enforce. Retry in case the policy is not yet
# registered; remove the Pod if it was admitted too early.
for _ in $(seq 1 10); do
  if ! kubectl run no-limits-checkout --image=nginx:alpine -n checkout-live 2>/dev/null; then
    break
  fi
  kubectl delete pod no-limits-checkout -n checkout-live --ignore-not-found
  sleep 5
done

# Admitted under Audit.
kubectl run no-limits-reporting --image=nginx:alpine -n reporting-live

kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=checkout-live"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
sleep 15

kubectl apply -f "$DIR/exception.yaml"
sleep 5
kubectl create job migration-job -n checkout-live --image=busybox:1.36 -- echo done
echo "[solution] Applied."
