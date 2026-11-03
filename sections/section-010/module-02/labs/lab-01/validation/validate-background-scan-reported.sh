#!/usr/bin/env bash
# Check: a PolicyReport exists in background-ns and legacy-worker still has no
# limits (the scan only reported; it did not change the Deployment).
set -u

limits=$(kubectl get deployment legacy-worker -n background-ns -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' 2>/dev/null)
if ! kubectl get deployment legacy-worker -n background-ns >/dev/null 2>&1; then
  echo "FAIL: legacy-worker - Deployment not found in background-ns; it must be left in place"
  exit 1
fi
if [[ -n "$limits" ]]; then
  echo "FAIL: legacy-worker - its container now has resource limits ($limits); the scan must report it, not change it"
  exit 1
fi

# The scan runs a short time after the policy is applied. Any report in the
# namespace proves that Kyverno evaluated the existing workload.
for _ in $(seq 1 40); do
  count=$(kubectl get polr -n background-ns -o json 2>/dev/null | jq -r '[.items[]?] | length' 2>/dev/null)
  if [[ "${count:-0}" -ge 1 ]]; then
    echo "PASS: PolicyReport objects exist in background-ns ($count) and legacy-worker was left without limits"
    exit 0
  fi
  sleep 3
done
echo "FAIL: background-ns - no PolicyReport found; the background scan did not run. Is the policy applied with background: true and matching Pod in background-ns?"
exit 1
