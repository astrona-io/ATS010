#!/usr/bin/env bash
# Check: no-limits-pod exists (admitted while the policy was in Audit) and a
# PolicyReport in platform-ns holds a failing result for it.
set -u

if ! kubectl get pod no-limits-pod -n platform-ns >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod missing from platform-ns - it should have been admitted while the policy was in Audit mode"
  exit 1
fi

# Reports are written by Kyverno controllers a few seconds after admission.
for _ in $(seq 1 30); do
  found=$(kubectl get polr -n platform-ns -o json 2>/dev/null | jq -r '[.items[].results[]? | select(.policy=="require-resource-limits" and .result=="fail") | .resources[]?.name] | map(select(. == "no-limits-pod")) | length' 2>/dev/null)
  if [[ "${found:-0}" -ge 1 ]]; then
    echo "PASS: no-limits-pod was admitted under Audit and is reported as a failing result of require-resource-limits"
    exit 0
  fi
  sleep 3
done
echo "FAIL: no failing result for no-limits-pod under require-resource-limits in kubectl get polr -n platform-ns - did the policy exist (in Audit mode, matching platform-ns) when the Pod was created?"
exit 1
