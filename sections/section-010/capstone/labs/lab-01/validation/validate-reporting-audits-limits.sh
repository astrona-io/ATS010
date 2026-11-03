#!/usr/bin/env bash
# Check: reporting-audit-limits is Ready, uses Audit, matches reporting-live,
# and a Pod without limits is admitted there.
set -u

policy_json=$(kubectl get clusterpolicy reporting-audit-limits -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: reporting-audit-limits - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | jq -r '.spec.validationFailureAction // empty')
if [[ "$action" != "Audit" ]]; then
  echo "FAIL: reporting-audit-limits - validationFailureAction is '$action', expected Audit"
  exit 1
fi

if ! echo "$policy_json" | jq -e '[.spec.rules[]?.match | tostring] | any(contains("reporting-live")) and any(contains("Pod"))' >/dev/null 2>&1; then
  echo "FAIL: reporting-audit-limits - no rule matches kind Pod in the reporting-live namespace"
  exit 1
fi

if ! kubectl get pod no-limits-reporting -n reporting-live >/dev/null 2>&1; then
  echo "FAIL: no-limits-reporting missing from reporting-live - it should have been admitted under Audit"
  exit 1
fi

for _ in $(seq 1 30); do
  ready=$(kubectl get clusterpolicy reporting-audit-limits -o json 2>/dev/null | jq -r '(.status.ready // false | tostring) + " " + ([.status.conditions[]? | select(.type=="Ready") | .status] | first // "none")')
  case "$ready" in
    "true "*|*" True") break ;;
  esac
  sleep 3
done
case "$ready" in
  "true "*|*" True") ;;
  *) echo "FAIL: reporting-audit-limits - policy is not Ready (status: $ready). Run kubectl describe clusterpolicy reporting-audit-limits"; exit 1 ;;
esac

if ! kubectl run grader-no-limits --image=nginx:alpine -n reporting-live --dry-run=server -o name >/dev/null 2>&1; then
  echo "FAIL: a Pod without limits was rejected in reporting-live - the policy there must use Audit"
  exit 1
fi
echo "PASS: reporting-audit-limits is Ready, uses Audit and admits a Pod without limits in reporting-live"
exit 0
