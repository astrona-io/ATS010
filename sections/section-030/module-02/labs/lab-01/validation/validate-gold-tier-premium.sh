#!/usr/bin/env bash
# Confirms team-a is tier=gold and carries cost-center premium, not standard.
set -u

tier=$(kubectl get namespace team-a -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [[ "$tier" != "gold" ]]; then
  echo "FAIL: team-a is not labelled tier=gold (tier='$tier')"
  exit 1
fi

for i in $(seq 1 30); do
  cc=$(kubectl get namespace team-a -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null)
  [[ -n "$cc" ]] && break
  sleep 2
done

if [[ "$cc" != "premium" ]]; then
  echo "FAIL: team-a cost-center is '$cc', expected premium (the gold rule must win, not the catch-all)"
  exit 1
fi

echo "PASS: team-a is tier=gold and has cost-center premium."
exit 0
