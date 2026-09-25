#!/usr/bin/env bash
# Confirms both ClusterPolicies exist with the correct failurePolicy/
# webhookTimeoutSeconds, that enforcement worked as expected in both
# namespaces, and that the admission controller was left healthy.

set -u

strict_json=$(kubectl get clusterpolicy require-app-label-strict -o json 2>/dev/null)
if [[ -z "$strict_json" ]]; then
  echo "FAIL: require-app-label-strict - ClusterPolicy not found"
  exit 1
fi

lenient_json=$(kubectl get clusterpolicy require-app-label-lenient -o json 2>/dev/null)
if [[ -z "$lenient_json" ]]; then
  echo "FAIL: require-app-label-lenient - ClusterPolicy not found"
  exit 1
fi

strict_fp=$(echo "$strict_json" | grep -o '"failurePolicy"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$strict_fp" != "Fail" ]]; then
  echo "FAIL: require-app-label-strict - failurePolicy is '$strict_fp', expected Fail"
  exit 1
fi

lenient_fp=$(echo "$lenient_json" | grep -o '"failurePolicy"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$lenient_fp" != "Ignore" ]]; then
  echo "FAIL: require-app-label-lenient - failurePolicy is '$lenient_fp', expected Ignore"
  exit 1
fi

strict_timeout=$(echo "$strict_json" | grep -o '"webhookTimeoutSeconds"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
if [[ "$strict_timeout" != "5" ]]; then
  echo "FAIL: require-app-label-strict - webhookTimeoutSeconds is '$strict_timeout', expected 5"
  exit 1
fi

lenient_timeout=$(echo "$lenient_json" | grep -o '"webhookTimeoutSeconds"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
if [[ "$lenient_timeout" != "5" ]]; then
  echo "FAIL: require-app-label-lenient - webhookTimeoutSeconds is '$lenient_timeout', expected 5"
  exit 1
fi

for ns in critical-ns lenient-ns; do
  if kubectl get pod no-app-pod -n "$ns" >/dev/null 2>&1; then
    echo "FAIL: no-app-pod exists in $ns - it should have been blocked by the policy"
    exit 1
  fi

  app_label=$(kubectl get pod has-app-pod -n "$ns" -o jsonpath='{.metadata.labels.app}' 2>/dev/null)
  if [[ -z "$app_label" ]]; then
    echo "FAIL: has-app-pod missing or has no 'app' label in $ns"
    exit 1
  fi
done

ready=$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
desired=$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [[ -z "$ready" || -z "$desired" || "$ready" -lt 1 || "$ready" != "$desired" ]]; then
  echo "FAIL: kyverno-admission-controller is not healthy (ready=$ready, desired=$desired) - restore it before finishing"
  exit 1
fi

echo "PASS: both policies enforce correctly with the required failurePolicy/webhookTimeoutSeconds settings, and the admission controller is healthy."
exit 0
