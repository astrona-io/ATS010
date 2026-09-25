#!/usr/bin/env bash
# Confirms require-resource-limits exists in Enforce mode, admitted the
# Audit-era Pod, blocked the post-Enforce violator, and admitted the
# compliant Pod.

set -u

policy_json=$(kubectl get clusterpolicy require-resource-limits -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-resource-limits - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-resource-limits - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! kubectl get pod no-limits-pod -n platform-ns >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod missing from platform-ns - it should have been admitted while the policy was in Audit mode"
  exit 1
fi

if kubectl get pod no-limits-pod-2 -n platform-ns >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod-2 exists in platform-ns - it should have been blocked by Enforce"
  exit 1
fi

cpu_limit=$(kubectl get pod has-limits-pod -n platform-ns -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
mem_limit=$(kubectl get pod has-limits-pod -n platform-ns -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [[ -z "$cpu_limit" || -z "$mem_limit" ]]; then
  echo "FAIL: has-limits-pod missing or missing cpu/memory limits in platform-ns"
  exit 1
fi

echo "PASS: require-resource-limits rolled out to Enforce, admitted no-limits-pod under Audit, blocked no-limits-pod-2 under Enforce, and admitted has-limits-pod (cpu=$cpu_limit, memory=$mem_limit)."
exit 0
