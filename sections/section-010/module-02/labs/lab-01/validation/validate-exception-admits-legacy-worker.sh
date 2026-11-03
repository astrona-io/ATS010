#!/usr/bin/env bash
# Check: allow-legacy-worker exists in background-ns, exempts the Pod rule and
# its autogen rule for names legacy-worker*, a Deployment with a matching name
# and no limits is admitted, and legacy-worker rolled a new Pod.
set -u

exception_json=$(kubectl get policyexception allow-legacy-worker -n background-ns -o json 2>/dev/null)
if [[ -z "$exception_json" ]]; then
  echo "FAIL: allow-legacy-worker - PolicyException not found in background-ns"
  exit 1
fi

policy_ok=$(echo "$exception_json" | jq -r '[.spec.exceptions[]? | select(.policyName=="require-resource-limits-bg") | .ruleNames[]?] | (index("check-resource-limits-bg") != null)')
if [[ "$policy_ok" != "true" ]]; then
  echo "FAIL: allow-legacy-worker - spec.exceptions must name policyName require-resource-limits-bg with ruleNames including check-resource-limits-bg"
  exit 1
fi

names_ok=$(echo "$exception_json" | jq -r '[.spec.match | tostring] | any(contains("legacy-worker"))')
if [[ "$names_ok" != "true" ]]; then
  echo "FAIL: allow-legacy-worker - spec.match must select resources named legacy-worker*"
  exit 1
fi

# A Deployment named like legacy-worker, without limits, must pass admission.
# This only works when the exception also covers the autogen rule.
manifest='{"apiVersion":"apps/v1","kind":"Deployment","metadata":{"name":"legacy-worker-grader"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"legacy-worker-grader"}},"template":{"metadata":{"labels":{"app":"legacy-worker-grader"}},"spec":{"containers":[{"name":"c","image":"nginx:alpine"}]}}}}'
accepted=0
for _ in $(seq 1 10); do
  if printf '%s' "$manifest" | kubectl create -n background-ns --dry-run=server -f - >/dev/null 2>&1; then
    accepted=1
    break
  fi
  sleep 3
done
if [[ "$accepted" -ne 1 ]]; then
  echo "FAIL: a Deployment named legacy-worker-grader without limits was rejected - the exception must also list the autogen- rule name, and PolicyExceptions must be enabled"
  exit 1
fi

for _ in $(seq 1 30); do
  json=$(kubectl get deployment legacy-worker -n background-ns -o json 2>/dev/null)
  generation=$(echo "$json" | jq -r '.metadata.generation // 0')
  ready=$(echo "$json" | jq -r '.status.readyReplicas // 0')
  updated=$(echo "$json" | jq -r '.status.updatedReplicas // 0')
  desired=$(echo "$json" | jq -r '.spec.replicas // 1')
  if [[ "$generation" -ge 2 && "$ready" -ge 1 && "$updated" -eq "$desired" ]]; then
    echo "PASS: allow-legacy-worker covers the Pod rule and its autogen rule, and legacy-worker rolled a new Pod without limits"
    exit 0
  fi
  sleep 3
done
echo "FAIL: legacy-worker - it has not rolled a new ready Pod (generation=$generation ready=$ready updated=$updated). Change an annotation in its Pod template to force a rollout"
exit 1
