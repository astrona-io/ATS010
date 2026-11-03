#!/usr/bin/env bash
# Check: checkout-require-limits is Ready, uses Enforce, matches checkout-live
# and rejects a Pod without limits there (server-side dry run).
set -u

policy_json=$(kubectl get clusterpolicy checkout-require-limits -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: checkout-require-limits - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | jq -r '.spec.validationFailureAction // empty')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: checkout-require-limits - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | jq -e '[.spec.rules[]?.match | tostring] | any(contains("checkout-live")) and any(contains("Pod"))' >/dev/null 2>&1; then
  echo "FAIL: checkout-require-limits - no rule matches kind Pod in the checkout-live namespace"
  exit 1
fi

if kubectl get pod no-limits-checkout -n checkout-live >/dev/null 2>&1; then
  echo "FAIL: no-limits-checkout exists in checkout-live - it should have been blocked by Enforce"
  exit 1
fi

for _ in $(seq 1 30); do
  ready=$(kubectl get clusterpolicy checkout-require-limits -o json 2>/dev/null | jq -r '(.status.ready // false | tostring) + " " + ([.status.conditions[]? | select(.type=="Ready") | .status] | first // "none")')
  case "$ready" in
    "true "*|*" True") break ;;
  esac
  sleep 3
done
case "$ready" in
  "true "*|*" True") ;;
  *) echo "FAIL: checkout-require-limits - policy is not Ready (status: $ready). Run kubectl describe clusterpolicy checkout-require-limits"; exit 1 ;;
esac

for _ in $(seq 1 15); do
  if ! kubectl run grader-no-limits --image=nginx:alpine -n checkout-live --dry-run=server -o name >/dev/null 2>&1; then
    echo "PASS: checkout-require-limits is Ready, uses Enforce and rejects a Pod without limits in checkout-live"
    exit 0
  fi
  sleep 3
done
echo "FAIL: a Pod without limits was accepted in checkout-live - the policy must Enforce for Pods in that namespace"
exit 1
