#!/usr/bin/env bash
# Check: a Deployment without limits is rejected in background-ns (server-side
# dry run, nothing is stored) and new-worker does not exist.
set -u

if kubectl get deployment new-worker -n background-ns >/dev/null 2>&1; then
  echo "FAIL: new-worker exists in background-ns - it should have been blocked by the autogen-extended rule"
  exit 1
fi

manifest='{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"name":"grader-new-worker"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"grader-new-worker"}},"template":{"metadata":{"labels":{"app":"grader-new-worker"}},"spec":{"containers":[{"name":"c","image":"nginx:alpine"}]}}}}'
for _ in $(seq 1 15); do
  if ! printf '%s' "$manifest" | kubectl create -n background-ns --dry-run=server -f - >/dev/null 2>&1; then
    echo "PASS: a Deployment without limits is rejected in background-ns and new-worker does not exist"
    exit 0
  fi
  sleep 3
done
echo "FAIL: a Deployment without limits was accepted in background-ns - the Enforce policy and its autogen rules must cover Deployments"
exit 1
