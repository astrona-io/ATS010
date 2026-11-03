#!/usr/bin/env bash
# Check: under Enforce, a Pod without limits is rejected (server-side dry
# run, nothing is stored) and no-limits-pod-2 was never created.
set -u

if kubectl get pod no-limits-pod-2 -n platform-ns >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod-2 exists in platform-ns - it should have been blocked by Enforce"
  exit 1
fi

# Kyverno may need a few seconds to register an updated policy.
for _ in $(seq 1 15); do
  if ! kubectl run grader-no-limits --image=nginx:alpine -n platform-ns --dry-run=server -o name >/dev/null 2>&1; then
    echo "PASS: a Pod without limits is rejected in platform-ns and no-limits-pod-2 does not exist"
    exit 0
  fi
  sleep 3
done
echo "FAIL: a Pod without limits was accepted in platform-ns - the policy must end in Enforce and match Pod in platform-ns"
exit 1
