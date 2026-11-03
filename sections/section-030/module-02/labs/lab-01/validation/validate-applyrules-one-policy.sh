#!/usr/bin/env bash
# Confirms label-namespace-by-tier has applyRules One and exactly two rules in
# the required order: gold-tier-override, then standard-tier-default.
set -u

POLICY="label-namespace-by-tier"

if ! kubectl get clusterpolicy "$POLICY" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $POLICY not found"
  exit 1
fi

apply_rules=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.applyRules}' 2>/dev/null)
if [[ "$apply_rules" != "One" ]]; then
  echo "FAIL: $POLICY applyRules is '$apply_rules', expected One"
  exit 1
fi

names=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{range .spec.rules[*]}{.name}{" "}{end}' 2>/dev/null)
if [[ "$names" != "gold-tier-override standard-tier-default " ]]; then
  echo "FAIL: $POLICY rules are '$names', expected 'gold-tier-override standard-tier-default' in that order"
  exit 1
fi

echo "PASS: $POLICY uses applyRules One with gold-tier-override listed before standard-tier-default."
exit 0
