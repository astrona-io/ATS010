#!/usr/bin/env bash
# Confirms ClusterPolicy require-app-label-lenient has failurePolicy Ignore, webhookTimeoutSeconds 5,
# validationFailureAction Enforce, and is Ready.
set -u

POLICY="require-app-label-lenient"

if ! kubectl get clusterpolicy "$POLICY" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $POLICY not found"
  exit 1
fi

fp=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.failurePolicy}' 2>/dev/null)
if [[ "$fp" != "Ignore" ]]; then
  echo "FAIL: $POLICY failurePolicy is '$fp', expected Ignore"
  exit 1
fi

timeout=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.webhookTimeoutSeconds}' 2>/dev/null)
if [[ "$timeout" != "5" ]]; then
  echo "FAIL: $POLICY webhookTimeoutSeconds is '$timeout', expected 5"
  exit 1
fi

action=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
if [[ "$(echo "$action" | tr "[:upper:]" "[:lower:]")" != "enforce" ]]; then
  echo "FAIL: $POLICY validationFailureAction is '$action', expected Enforce"
  exit 1
fi

for i in $(seq 1 30); do
  ready=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [[ "$ready" == "True" ]] && break
  sleep 2
done
if [[ "$ready" != "True" ]]; then
  echo "FAIL: $POLICY is not Ready yet"
  exit 1
fi

echo "PASS: $POLICY has failurePolicy Ignore, webhookTimeoutSeconds 5, Enforce, and is Ready."
exit 0
