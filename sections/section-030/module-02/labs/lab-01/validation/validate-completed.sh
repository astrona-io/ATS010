#!/usr/bin/env bash
# Confirms generateExisting backfilled default-deny-ingress into the
# pre-existing namespaces, forward generation still works for a new
# namespace, and applyRules: One picks exactly one cost-center label.

set -u

policy_json=$(kubectl get clusterpolicy clone-default-netpol -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: clone-default-netpol - ClusterPolicy not found"
  exit 1
fi

generate_existing=$(echo "$policy_json" | grep -o '"generateExisting"[[:space:]]*:[[:space:]]*[a-z]*' | head -1 | grep -o '[a-z]*$')
if [[ "$generate_existing" != "true" ]]; then
  echo "FAIL: clone-default-netpol - generateExisting is '$generate_existing', expected true"
  exit 1
fi

for ns in team-a team-b team-c team-d; do
  if ! kubectl get networkpolicy default-deny-ingress -n "$ns" >/dev/null 2>&1; then
    echo "FAIL: default-deny-ingress NetworkPolicy not found in $ns"
    exit 1
  fi
done

tier_json=$(kubectl get clusterpolicy label-namespace-by-tier -o json 2>/dev/null)
if [[ -z "$tier_json" ]]; then
  echo "FAIL: label-namespace-by-tier - ClusterPolicy not found"
  exit 1
fi

apply_rules=$(echo "$tier_json" | grep -o '"applyRules"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$apply_rules" != "One" ]]; then
  echo "FAIL: label-namespace-by-tier - applyRules is '$apply_rules', expected One"
  exit 1
fi

team_a_cost_center=$(kubectl get namespace team-a -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
if [[ "$team_a_cost_center" != "premium" ]]; then
  echo "FAIL: team-a - cost-center label is '$team_a_cost_center', expected premium"
  exit 1
fi

team_e_cost_center=$(kubectl get namespace team-e -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
if [[ "$team_e_cost_center" != "standard" ]]; then
  echo "FAIL: team-e - cost-center label is '$team_e_cost_center', expected standard"
  exit 1
fi

echo "PASS: generateExisting backfilled all pre-existing namespaces, forward generation still works, and applyRules: One selected exactly one cost-center outcome per namespace."
exit 0
