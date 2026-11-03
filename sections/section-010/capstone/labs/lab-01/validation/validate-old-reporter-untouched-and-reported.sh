#!/usr/bin/env bash
# Check: old-reporter is ready and still has no limits, and a PolicyReport
# exists in reporting-live (the scan reported without changing anything).
set -u

if ! kubectl get deployment old-reporter -n reporting-live >/dev/null 2>&1; then
  echo "FAIL: old-reporter - Deployment not found in reporting-live; it should have been left untouched"
  exit 1
fi
ready_replicas=$(kubectl get deployment old-reporter -n reporting-live -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [[ -z "$ready_replicas" || "$ready_replicas" -lt 1 ]]; then
  echo "FAIL: old-reporter - Deployment is not ready in reporting-live"
  exit 1
fi
limits=$(kubectl get deployment old-reporter -n reporting-live -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' 2>/dev/null)
if [[ -n "$limits" ]]; then
  echo "FAIL: old-reporter - it now has resource limits ($limits); the scan must report it, not change it"
  exit 1
fi

for _ in $(seq 1 40); do
  count=$(kubectl get polr -n reporting-live -o json 2>/dev/null | jq -r '[.items[]?] | length' 2>/dev/null)
  if [[ "${count:-0}" -ge 1 ]]; then
    echo "PASS: old-reporter is untouched and PolicyReport objects exist in reporting-live ($count)"
    exit 0
  fi
  sleep 3
done
echo "FAIL: reporting-live - no PolicyReport found; the background scan did not run. Is reporting-audit-limits applied with background: true?"
exit 1
