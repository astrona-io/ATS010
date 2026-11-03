#!/usr/bin/env bash
# Check: has-limits-pod exists with both limits, and a compliant Pod is
# still accepted by a server-side dry run.
set -u

cpu_limit=$(kubectl get pod has-limits-pod -n platform-ns -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
mem_limit=$(kubectl get pod has-limits-pod -n platform-ns -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [[ -z "$cpu_limit" || -z "$mem_limit" ]]; then
  echo "FAIL: has-limits-pod is missing from platform-ns or does not set both limits.cpu and limits.memory"
  exit 1
fi

manifest='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"grader-with-limits"},"spec":{"containers":[{"name":"c","image":"nginx:alpine","resources":{"limits":{"cpu":"100m","memory":"64Mi"}}}]}}'
for _ in $(seq 1 5); do
  if printf '%s' "$manifest" | kubectl create -n platform-ns --dry-run=server -f - >/dev/null 2>&1; then
    echo "PASS: has-limits-pod exists (cpu=$cpu_limit, memory=$mem_limit) and a compliant Pod is still admitted"
    exit 0
  fi
  sleep 3
done
echo "FAIL: a Pod with both limits was rejected in platform-ns - the pattern is too strict"
exit 1
