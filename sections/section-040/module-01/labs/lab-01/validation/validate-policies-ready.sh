#!/usr/bin/env bash
# Check: the three ClusterPolicies exist and Kyverno reports each one as Ready.
set -u

fail=0
for policy in pod-defaults require-pod-standards protect-registry; do
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
exit "$fail"
