#!/usr/bin/env bash
# Check: three ClusterPolicies are Ready and the ClusterCleanupPolicy exists.
set -u

fail=0
for policy in onboard-namespace workload-defaults workload-guardrails; do
  if ! kubectl get clusterpolicy "$policy" >/dev/null 2>&1; then
    echo "FAIL: ClusterPolicy $policy not found"
    fail=1
    continue
  fi
  ready=""
  for i in $(seq 1 45); do
    ready="$(kubectl get clusterpolicy "$policy" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    [ "$ready" = "True" ] && break
    sleep 2
  done
  if [ "$ready" = "True" ]; then
    echo "PASS: $policy is Ready"
  else
    echo "FAIL: $policy is not Ready after 90 seconds (run: kubectl describe clusterpolicy $policy)"
    fail=1
  fi
done
if kubectl get clustercleanuppolicy expire-shipyard-configmaps >/dev/null 2>&1; then
  echo "PASS: ClusterCleanupPolicy expire-shipyard-configmaps exists"
else
  echo "FAIL: ClusterCleanupPolicy expire-shipyard-configmaps not found"
  fail=1
fi
exit "$fail"
