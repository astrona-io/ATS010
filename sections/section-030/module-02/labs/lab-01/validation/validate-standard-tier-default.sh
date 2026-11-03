#!/usr/bin/env bash
# Confirms team-e exists without a tier label and carries cost-center standard.
set -u

if ! kubectl get namespace team-e >/dev/null 2>&1; then
  echo "FAIL: namespace team-e does not exist - create it after applying label-namespace-by-tier"
  exit 1
fi

tier=$(kubectl get namespace team-e -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [[ -n "$tier" ]]; then
  echo "FAIL: team-e has tier='$tier' - it must have no tier label"
  exit 1
fi

for i in $(seq 1 30); do
  cc=$(kubectl get namespace team-e -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
  [[ -n "$cc" ]] && break
  sleep 2
done

if [[ "$cc" != "standard" ]]; then
  echo "FAIL: team-e cost-center is '$cc', expected standard from the catch-all rule"
  exit 1
fi

echo "PASS: team-e has no tier label and cost-center standard."
exit 0
