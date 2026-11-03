#!/usr/bin/env bash
# Check: the tested policy require-limits is applied to the cluster, is Ready,
# and the cluster rejects a Pod without memory limits.
set -u
M="${HOME}/kyverno-lab/m2"
fail=0

ready=""
for i in $(seq 1 30); do
  ready="$(kubectl get clusterpolicy require-limits -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$ready" = "True" ] && break
  sleep 2
done
if [ "$ready" != "True" ]; then
  echo "FAIL: ClusterPolicy require-limits is not applied and Ready in the cluster"
  exit 1
fi
echo "PASS: ClusterPolicy require-limits is Ready"

if kubectl apply --dry-run=server -f "${M}/resources/pod-no-limits.yaml" >/dev/null 2>&1; then
  echo "FAIL: the cluster admitted web-nolimits; the policy should reject it"; fail=1
else
  echo "PASS: the cluster rejects web-nolimits"
fi
if kubectl apply --dry-run=server -f "${M}/resources/pod-with-limits.yaml" >/dev/null 2>&1; then
  echo "PASS: the cluster admits web-ok"
else
  echo "FAIL: the cluster rejected web-ok"; fail=1
fi
exit "$fail"
