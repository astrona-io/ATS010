#!/usr/bin/env bash
# Check: require-resource-limits-bg exists, is Ready, uses Enforce, scans in
# the background and has autogen rules.
set -u

policy_json=$(kubectl get clusterpolicy require-resource-limits-bg -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-resource-limits-bg - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | jq -r '.spec.validationFailureAction // empty')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-resource-limits-bg - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

background=$(echo "$policy_json" | jq -r '.spec.background // true')
if [[ "$background" != "true" ]]; then
  echo "FAIL: require-resource-limits-bg - background is '$background', expected true"
  exit 1
fi

# Autogen evidence: generated rules in status (1.13) or in spec (older
# versions), or an autogen-controllers annotation that is not "none".
autogen_rules=$(echo "$policy_json" | jq -r '[(.status.autogen.rules[]?.name), (.spec.rules[]?.name)] | map(select(startswith("autogen-"))) | length')
annotation=$(echo "$policy_json" | jq -r '.metadata.annotations["pod-policies.kyverno.io/autogen-controllers"] // ""')
if [[ "$annotation" == "none" ]]; then
  echo "FAIL: require-resource-limits-bg - the autogen-controllers annotation is 'none'; autogen is disabled"
  exit 1
fi
if [[ "${autogen_rules:-0}" -eq 0 && -z "$annotation" ]]; then
  echo "FAIL: require-resource-limits-bg - no autogen- rules found in status or spec and no autogen-controllers annotation; run kubectl get clusterpolicy require-resource-limits-bg -o yaml"
  exit 1
fi

for _ in $(seq 1 30); do
  ready=$(kubectl get clusterpolicy require-resource-limits-bg -o json 2>/dev/null | jq -r '(.status.ready // false | tostring) + " " + ([.status.conditions[]? | select(.type=="Ready") | .status] | first // "none")')
  case "$ready" in
    "true "*|*" True") echo "PASS: require-resource-limits-bg is Ready, uses Enforce, scans in the background and has autogen rules"; exit 0 ;;
  esac
  sleep 3
done
echo "FAIL: require-resource-limits-bg - policy is not Ready (status: $ready). Run kubectl describe clusterpolicy require-resource-limits-bg"
exit 1
