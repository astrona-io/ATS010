#!/usr/bin/env bash
# Check: the Kyverno admission controller runs with PolicyException support on
# and limited to checkout-live, and its rollout has finished.
set -u

args=$(kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null)
if ! echo "$args" | grep -q "enablePolicyException=true"; then
  echo "FAIL: kyverno-admission-controller - --enablePolicyException=true is not set"
  exit 1
fi
if ! echo "$args" | grep -q "exceptionNamespace=checkout-live"; then
  echo "FAIL: kyverno-admission-controller - --exceptionNamespace=checkout-live is not set"
  exit 1
fi

for _ in $(seq 1 40); do
  json=$(kubectl get deployment kyverno-admission-controller -n kyverno -o json 2>/dev/null)
  desired=$(echo "$json" | jq -r '.spec.replicas // 1')
  updated=$(echo "$json" | jq -r '.status.updatedReplicas // 0')
  available=$(echo "$json" | jq -r '.status.availableReplicas // 0')
  total=$(echo "$json" | jq -r '.status.replicas // 0')
  if [[ "$updated" -eq "$desired" && "$available" -ge "$desired" && "$total" -eq "$desired" ]]; then
    echo "PASS: the admission controller runs with --enablePolicyException=true and --exceptionNamespace=checkout-live"
    exit 0
  fi
  sleep 3
done
echo "FAIL: kyverno-admission-controller - the rollout after the patch has not finished (desired=$desired updated=$updated available=$available total=$total)"
exit 1
