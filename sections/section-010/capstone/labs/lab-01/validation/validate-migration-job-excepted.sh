#!/usr/bin/env bash
# Check: allow-migration-job exempts migration-job* from checkout-require-limits
# (Pod rule and autogen rule), a Job named like it is admitted without
# limits, and migration-job exists and created a Pod.
set -u

exception_json=$(kubectl get policyexception allow-migration-job -n checkout-live -o json 2>/dev/null)
if [[ -z "$exception_json" ]]; then
  echo "FAIL: allow-migration-job - PolicyException not found in checkout-live"
  exit 1
fi

rule_ok=$(echo "$exception_json" | jq -r '[.spec.exceptions[]? | select(.policyName=="checkout-require-limits") | .ruleNames[]?] | (index("check-limits-checkout") != null)')
if [[ "$rule_ok" != "true" ]]; then
  echo "FAIL: allow-migration-job - spec.exceptions must name policyName checkout-require-limits with ruleNames including check-limits-checkout"
  exit 1
fi
names_ok=$(echo "$exception_json" | jq -r '[.spec.match | tostring] | any(contains("migration-job"))')
if [[ "$names_ok" != "true" ]]; then
  echo "FAIL: allow-migration-job - spec.match must select resources named migration-job*"
  exit 1
fi

# A Job named like migration-job, without limits, must pass admission. This
# only works when the exception also covers the autogen rule for Jobs.
manifest='{"apiVersion":"batch/v1","kind":"Job","metadata":{"name":"migration-job-grader"},"spec":{"template":{"spec":{"restartPolicy":"Never","containers":[{"name":"c","image":"busybox:1.36","command":["echo","done"]}]}}}}'
accepted=0
for _ in $(seq 1 10); do
  if printf '%s' "$manifest" | kubectl create -n checkout-live --dry-run=server -f - >/dev/null 2>&1; then
    accepted=1
    break
  fi
  sleep 3
done
if [[ "$accepted" -ne 1 ]]; then
  echo "FAIL: a Job named migration-job-grader without limits was rejected - the exception must also list the autogen- rule name, and PolicyExceptions must be enabled"
  exit 1
fi

if ! kubectl get job migration-job -n checkout-live >/dev/null 2>&1; then
  echo "FAIL: migration-job - Job not found in checkout-live; the PolicyException may not be working"
  exit 1
fi
for _ in $(seq 1 30); do
  pods=$(kubectl get pods -n checkout-live -l job-name=migration-job -o name 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$pods" -ge 1 ]]; then
    echo "PASS: allow-migration-job covers the Pod rule and its autogen rule, and migration-job was admitted and created a Pod"
    exit 0
  fi
  sleep 3
done
echo "FAIL: migration-job - the Job exists but created no Pod; the Pod rule may not be covered by the exception"
exit 1
