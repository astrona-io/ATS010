#!/usr/bin/env bash
# Check: the generate policy is Ready and the cleanup policy exists.
set -u

fail=0
if ! kubectl get clusterpolicy namespace-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy namespace-defaults not found"
  fail=1
else
  ready=""
  for i in $(seq 1 45); do
    ready="$(kubectl get clusterpolicy namespace-defaults -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    [ "$ready" = "True" ] && break
    sleep 2
  done
  if [ "$ready" = "True" ]; then
    echo "PASS: namespace-defaults is Ready"
  else
    echo "FAIL: namespace-defaults is not Ready after 90 seconds (run: kubectl describe clusterpolicy namespace-defaults)"
    fail=1
  fi
fi

if kubectl get clustercleanuppolicy remove-expired-configmaps >/dev/null 2>&1; then
  echo "PASS: ClusterCleanupPolicy remove-expired-configmaps exists"
else
  echo "FAIL: ClusterCleanupPolicy remove-expired-configmaps not found"
  fail=1
fi
exit "$fail"
