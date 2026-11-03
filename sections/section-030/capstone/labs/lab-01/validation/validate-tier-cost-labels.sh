#!/usr/bin/env bash
# Confirms tier-cost-labels uses applyRules One with the gold rule first, and
# that ops-prod (tier=gold) ends with cost-center premium.
set -u

P="tier-cost-labels"
if ! kubectl get clusterpolicy "$P" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $P not found"
  exit 1
fi

ar=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.applyRules}')
if [[ "$ar" != "One" ]]; then
  echo "FAIL: $P applyRules is '$ar', expected One"
  exit 1
fi

names=$(kubectl get clusterpolicy "$P" -o jsonpath='{range .spec.rules[*]}{.name}{" "}{end}')
if [[ "$names" != "gold-tier-override standard-tier-default " ]]; then
  echo "FAIL: $P rules are '$names', expected 'gold-tier-override standard-tier-default' in that order"
  exit 1
fi

tier=$(kubectl get namespace ops-prod -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [[ "$tier" != "gold" ]]; then
  echo "FAIL: ops-prod is not labelled tier=gold (tier='$tier')"
  exit 1
fi

for i in $(seq 1 30); do
  cc=$(kubectl get namespace ops-prod -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
  [[ -n "$cc" ]] && break
  sleep 2
done
if [[ "$cc" != "premium" ]]; then
  echo "FAIL: ops-prod cost-center is '$cc', expected premium"
  exit 1
fi

echo "PASS: tier-cost-labels uses applyRules One and ops-prod has cost-center premium."
exit 0
