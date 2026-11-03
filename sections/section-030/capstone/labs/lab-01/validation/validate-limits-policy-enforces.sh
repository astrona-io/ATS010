#!/usr/bin/env bash
# Confirms ops-require-limits has Fail / 8s / Enforce / background true, rejects
# a Pod without limits (server dry run), and has-limits-pod was admitted.
set -u

P="ops-require-limits"
if ! kubectl get clusterpolicy "$P" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $P not found"
  exit 1
fi

fp=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.failurePolicy}')
timeout=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.webhookTimeoutSeconds}')
action=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.validationFailureAction}' | tr '[:upper:]' '[:lower:]')
bg=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.background}')
if [[ "$fp" != "Fail" ]]; then echo "FAIL: $P failurePolicy is '$fp', expected Fail"; exit 1; fi
if [[ "$timeout" != "8" ]]; then echo "FAIL: $P webhookTimeoutSeconds is '$timeout', expected 8"; exit 1; fi
if [[ "$action" != "enforce" ]]; then echo "FAIL: $P validationFailureAction is '$action', expected Enforce"; exit 1; fi
if [[ "$bg" != "true" ]]; then echo "FAIL: $P background is '$bg', expected true"; exit 1; fi

denied=0
for i in $(seq 1 30); do
  if ! kubectl apply --dry-run=server -n ops-prod -f - >/dev/null 2>&1 <<POD
apiVersion: v1
kind: Pod
metadata:
  name: validation-probe
spec:
  containers:
    - name: c
      image: nginx:alpine
POD
  then
    denied=1
    break
  fi
  sleep 2
done
if [[ "$denied" != "1" ]]; then
  echo "FAIL: a Pod without resource limits was not rejected in ops-prod"
  exit 1
fi

if kubectl get pod no-limits-pod -n ops-prod >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod exists in ops-prod - it should have been blocked"
  exit 1
fi

cpu=$(kubectl get pod has-limits-pod -n ops-prod -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
mem=$(kubectl get pod has-limits-pod -n ops-prod -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [[ -z "$cpu" || -z "$mem" ]]; then
  echo "FAIL: has-limits-pod missing in ops-prod or has no cpu/memory limits (cpu='$cpu', memory='$mem')"
  exit 1
fi

echo "PASS: ops-require-limits enforces limits with Fail / 8s / background true and has-limits-pod was admitted."
exit 0
