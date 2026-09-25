#!/usr/bin/env bash
# Confirms restrict-frontend-images exists, is Enforce, blocked frontend-pod,
# admitted ci-pod (excluded subject), and admitted backend-pod (out of
# objectSelector scope).

set -u

policy_json=$(kubectl get clusterpolicy restrict-frontend-images -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: restrict-frontend-images - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: restrict-frontend-images - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | grep -q "ci-deployer"; then
  echo "FAIL: restrict-frontend-images - policy does not exclude the ci-deployer ServiceAccount"
  exit 1
fi

if kubectl get pod frontend-pod -n apps-ns >/dev/null 2>&1; then
  echo "FAIL: frontend-pod exists in apps-ns - it should have been blocked by the policy"
  exit 1
fi

if ! kubectl get pod ci-pod -n apps-ns >/dev/null 2>&1; then
  echo "FAIL: ci-pod missing from apps-ns - it should have been excluded (ci-deployer subject) and admitted"
  exit 1
fi

if ! kubectl get pod backend-pod -n apps-ns >/dev/null 2>&1; then
  echo "FAIL: backend-pod missing from apps-ns - it should have been out of objectSelector scope and admitted"
  exit 1
fi

echo "PASS: restrict-frontend-images enforces the image pattern on tier=frontend Pods, excludes ci-deployer, blocked frontend-pod, and admitted ci-pod and backend-pod."
exit 0
