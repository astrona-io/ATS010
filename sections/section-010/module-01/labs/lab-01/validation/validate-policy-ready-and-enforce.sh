#!/usr/bin/env bash
# Check: require-resource-limits exists, is Ready, matches Pods in
# platform-ns and ends in Enforce.
set -u

policy_json=$(kubectl get clusterpolicy require-resource-limits -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-resource-limits - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | jq -r '.spec.validationFailureAction // empty')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-resource-limits - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | jq -e '[.spec.rules[]?.match | tostring] | any(contains("platform-ns")) and any(contains("Pod"))' >/dev/null 2>&1; then
  echo "FAIL: require-resource-limits - no rule matches kind Pod in the platform-ns namespace"
  exit 1
fi

# Ready: Kyverno 1.13 fills status.ready and a Ready condition. Accept either.
for _ in $(seq 1 30); do
  ready=$(kubectl get clusterpolicy require-resource-limits -o json 2>/dev/null | jq -r '(.status.ready // false | tostring) + " " + ([.status.conditions[]? | select(.type=="Ready") | .status] | first // "none")')
  case "$ready" in
    "true "*|*" True") echo "PASS: require-resource-limits is Ready, matches Pods in platform-ns and uses Enforce"; exit 0 ;;
  esac
  sleep 3
done
echo "FAIL: require-resource-limits - policy is not Ready (status: $ready). Run kubectl describe clusterpolicy require-resource-limits"
exit 1
