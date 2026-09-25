#!/usr/bin/env bash
# Confirms require-resource-limits-bg is live with autogen, the background
# scan flagged legacy-worker, new-worker was blocked, PolicyExceptions are
# enabled and scoped, and the exception let a re-rolled legacy-worker
# through.

set -u

policy_json=$(kubectl get clusterpolicy require-resource-limits-bg -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-resource-limits-bg - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-resource-limits-bg - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | grep -q "autogen-controllers"; then
  echo "FAIL: require-resource-limits-bg - no pod-policies.kyverno.io/autogen-controllers annotation found; autogen may be disabled"
  exit 1
fi

report_count=$(kubectl get polr -n background-ns -o name 2>/dev/null | wc -l | tr -d ' ')
if [[ "$report_count" -eq 0 ]]; then
  echo "FAIL: background-ns - no PolicyReport found; background scan of legacy-worker did not run or found nothing"
  exit 1
fi

if kubectl get deployment new-worker -n background-ns >/dev/null 2>&1; then
  echo "FAIL: new-worker exists in background-ns - it should have been blocked by autogen-extended admission"
  exit 1
fi

admission_args=$(kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null)
if ! echo "$admission_args" | grep -q "enablePolicyException=true"; then
  echo "FAIL: kyverno-admission-controller - --enablePolicyException=true not set"
  exit 1
fi
if ! echo "$admission_args" | grep -q "exceptionNamespace=background-ns"; then
  echo "FAIL: kyverno-admission-controller - --exceptionNamespace=background-ns not set"
  exit 1
fi

if ! kubectl get policyexception allow-legacy-worker -n background-ns >/dev/null 2>&1; then
  echo "FAIL: allow-legacy-worker - PolicyException not found in background-ns"
  exit 1
fi

ready_replicas=$(kubectl get deployment legacy-worker -n background-ns -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [[ -z "$ready_replicas" || "$ready_replicas" -lt 1 ]]; then
  echo "FAIL: legacy-worker - Deployment is not ready in background-ns; the PolicyException may not be working"
  exit 1
fi

echo "PASS: autogen present, background scan populated a report, new-worker blocked, PolicyExceptions enabled and scoped to background-ns, allow-legacy-worker exists, and legacy-worker is ready."
exit 0
