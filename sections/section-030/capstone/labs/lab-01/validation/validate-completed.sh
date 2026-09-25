#!/usr/bin/env bash
# Confirms ops-require-limits enforces correctly with the required
# failurePolicy/webhookTimeoutSeconds, clone-audit-configmap backfilled
# audit-config into the pre-existing ops-legacy namespace, and
# tier-cost-labels (applyRules: One) picked exactly one cost-center label.

set -u

limits_json=$(kubectl get clusterpolicy ops-require-limits -o json 2>/dev/null)
if [[ -z "$limits_json" ]]; then
  echo "FAIL: ops-require-limits - ClusterPolicy not found"
  exit 1
fi

fp=$(echo "$limits_json" | grep -o '"failurePolicy"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$fp" != "Fail" ]]; then
  echo "FAIL: ops-require-limits - failurePolicy is '$fp', expected Fail"
  exit 1
fi

timeout=$(echo "$limits_json" | grep -o '"webhookTimeoutSeconds"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
if [[ "$timeout" != "8" ]]; then
  echo "FAIL: ops-require-limits - webhookTimeoutSeconds is '$timeout', expected 8"
  exit 1
fi

if kubectl get pod no-limits-pod -n ops-prod >/dev/null 2>&1; then
  echo "FAIL: no-limits-pod exists in ops-prod - it should have been blocked by ops-require-limits"
  exit 1
fi

if ! kubectl get pod has-limits-pod -n ops-prod >/dev/null 2>&1; then
  echo "FAIL: has-limits-pod not found in ops-prod - it should have been admitted"
  exit 1
fi

audit_json=$(kubectl get clusterpolicy clone-audit-configmap -o json 2>/dev/null)
if [[ -z "$audit_json" ]]; then
  echo "FAIL: clone-audit-configmap - ClusterPolicy not found"
  exit 1
fi

generate_existing=$(echo "$audit_json" | grep -o '"generateExisting"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | grep -o '[a-z]*$')
if [[ "$generate_existing" != "true" ]]; then
  echo "FAIL: clone-audit-configmap - generateExisting is '$generate_existing', expected true"
  exit 1
fi

for ns in ops-prod ops-legacy; do
  if ! kubectl get configmap audit-config -n "$ns" >/dev/null 2>&1; then
    echo "FAIL: audit-config ConfigMap not found in $ns"
    exit 1
  fi
done

tier_json=$(kubectl get clusterpolicy tier-cost-labels -o json 2>/dev/null)
if [[ -z "$tier_json" ]]; then
  echo "FAIL: tier-cost-labels - ClusterPolicy not found"
  exit 1
fi

apply_rules=$(echo "$tier_json" | grep -o '"applyRules"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$apply_rules" != "One" ]]; then
  echo "FAIL: tier-cost-labels - applyRules is '$apply_rules', expected One"
  exit 1
fi

ops_prod_cost_center=$(kubectl get namespace ops-prod -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
if [[ "$ops_prod_cost_center" != "premium" ]]; then
  echo "FAIL: ops-prod - cost-center label is '$ops_prod_cost_center', expected premium"
  exit 1
fi

echo "PASS: resource-limit enforcement, retroactive audit-config generation, and applyRules: One tier labeling all behave as required."
exit 0
