#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# ClusterRoles are aggregated and the three ClusterPolicies are ready.
set -euo pipefail

ok=0
for i in $(seq 1 60); do
  a="$(kubectl auth can-i create networkpolicies --as=system:serviceaccount:kyverno:kyverno-background-controller 2>/dev/null || true)"
  b="$(kubectl auth can-i delete configmaps --as=system:serviceaccount:kyverno:kyverno-cleanup-controller 2>/dev/null || true)"
  all=1
  for p in onboard-namespace workload-defaults workload-guardrails; do
    r="$(kubectl get clusterpolicy "$p" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    [ "$r" = "True" ] || all=0
  done
  if [ "$a" = "yes" ] && [ "$b" = "yes" ] && [ "$all" -eq 1 ]; then
    ok=1
    break
  fi
  sleep 2
done
if [ "$ok" -ne 1 ]; then
  echo "[testing] controllers or policies were not ready in time." >&2
  exit 1
fi
sleep 10
echo "[testing] ready."
