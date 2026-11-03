#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/policy.yaml"
kubectl wait --for=condition=Ready clusterpolicy/require-resource-limits-bg --timeout=120s || true
sleep 20

# Expected to be rejected: autogen extends the Pod rule to Deployments.
for _ in $(seq 1 10); do
  if ! kubectl apply -f "$DIR/new-worker.yaml" 2>/dev/null; then
    break
  fi
  # It was accepted before Kyverno registered the policy: remove and retry.
  kubectl delete -f "$DIR/new-worker.yaml" --ignore-not-found
  sleep 5
done

kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=background-ns"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
sleep 15

kubectl apply -f "$DIR/exception.yaml"
sleep 5
kubectl -n background-ns patch deployment legacy-worker -p '{"spec":{"template":{"metadata":{"annotations":{"force-reroll":"1"}}}}}'
kubectl -n background-ns rollout status deployment/legacy-worker --timeout=180s
echo "[solution] Applied."
