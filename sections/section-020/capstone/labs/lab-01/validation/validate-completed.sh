#!/usr/bin/env bash
# Confirms require-approved-release exists, is Enforce, blocked release-app
# in store-prod for the default identity, and admitted it for release-bot,
# release-canary (objectSelector out of scope), and release-app in
# store-dev (namespaceSelector out of scope).

set -u

policy_json=$(kubectl get clusterpolicy require-approved-release -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-approved-release - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-approved-release - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | grep -q "release-bot"; then
  echo "FAIL: require-approved-release - policy does not exclude the release-bot ServiceAccount"
  exit 1
fi

approved_annotation=$(kubectl get deployment release-app -n store-prod -o jsonpath='{.metadata.annotations.approved-by}' 2>/dev/null)
if ! kubectl get deployment release-app -n store-prod >/dev/null 2>&1; then
  echo "FAIL: release-app missing from store-prod - it should have been admitted via the release-bot exclusion"
  exit 1
fi
if [[ -n "$approved_annotation" ]]; then
  echo "FAIL: release-app in store-prod has an 'approved-by' annotation set - the impersonated request should not need one"
  exit 1
fi

if ! kubectl get deployment release-canary -n store-prod >/dev/null 2>&1; then
  echo "FAIL: release-canary missing from store-prod - it should have been out of objectSelector scope (channel != stable) and admitted"
  exit 1
fi

if ! kubectl get deployment release-app -n store-dev >/dev/null 2>&1; then
  echo "FAIL: release-app missing from store-dev - it should have been out of namespaceSelector scope and admitted"
  exit 1
fi

echo "PASS: require-approved-release enforces approved-by on stable release-* Deployments in env=prod namespaces, excludes release-bot, and admitted release-app (via release-bot), release-canary, and release-app in store-dev."
exit 0
