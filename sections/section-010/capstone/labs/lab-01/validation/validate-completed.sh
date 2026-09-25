#!/usr/bin/env bash
# Confirms the section-010 capstone: Enforce blocks in checkout-live, Audit
# reports without touching reporting-live, and PolicyExceptions admit the
# migration Job in checkout-live.

set -u

checkout_json=$(kubectl get clusterpolicy checkout-require-limits -o json 2>/dev/null)
if [[ -z "$checkout_json" ]]; then
  echo "FAIL: checkout-require-limits - ClusterPolicy not found"
  exit 1
fi
checkout_action=$(echo "$checkout_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$checkout_action" != "Enforce" ]]; then
  echo "FAIL: checkout-require-limits - validationFailureAction is '$checkout_action', expected Enforce"
  exit 1
fi

reporting_json=$(kubectl get clusterpolicy reporting-audit-limits -o json 2>/dev/null)
if [[ -z "$reporting_json" ]]; then
  echo "FAIL: reporting-audit-limits - ClusterPolicy not found"
  exit 1
fi
reporting_action=$(echo "$reporting_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$reporting_action" != "Audit" ]]; then
  echo "FAIL: reporting-audit-limits - validationFailureAction is '$reporting_action', expected Audit"
  exit 1
fi

if kubectl get pod no-limits-checkout -n checkout-live >/dev/null 2>&1; then
  echo "FAIL: no-limits-checkout exists in checkout-live - it should have been blocked by Enforce"
  exit 1
fi

if ! kubectl get pod no-limits-reporting -n reporting-live >/dev/null 2>&1; then
  echo "FAIL: no-limits-reporting missing from reporting-live - it should have been admitted under Audit"
  exit 1
fi

ready_replicas=$(kubectl get deployment old-reporter -n reporting-live -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [[ -z "$ready_replicas" || "$ready_replicas" -lt 1 ]]; then
  echo "FAIL: old-reporter - Deployment missing or not ready in reporting-live; it should have been left untouched"
  exit 1
fi

report_count=$(kubectl get polr -n reporting-live -o name 2>/dev/null | wc -l | tr -d ' ')
if [[ "$report_count" -eq 0 ]]; then
  echo "FAIL: reporting-live - no PolicyReport found; background scan of old-reporter did not run or found nothing"
  exit 1
fi

admission_args=$(kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null)
if ! echo "$admission_args" | grep -q "enablePolicyException=true"; then
  echo "FAIL: kyverno-admission-controller - --enablePolicyException=true not set"
  exit 1
fi
if ! echo "$admission_args" | grep -q "exceptionNamespace=checkout-live"; then
  echo "FAIL: kyverno-admission-controller - --exceptionNamespace=checkout-live not set"
  exit 1
fi

if ! kubectl get policyexception allow-migration-job -n checkout-live >/dev/null 2>&1; then
  echo "FAIL: allow-migration-job - PolicyException not found in checkout-live"
  exit 1
fi

if ! kubectl get job migration-job -n checkout-live >/dev/null 2>&1; then
  echo "FAIL: migration-job - Job not found in checkout-live; the PolicyException may not be working"
  exit 1
fi

echo "PASS: checkout-live enforces limits and admits the excepted migration-job, reporting-live audits and left old-reporter untouched but reported."
exit 0
