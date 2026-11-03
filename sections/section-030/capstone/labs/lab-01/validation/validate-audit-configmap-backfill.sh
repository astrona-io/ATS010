#!/usr/bin/env bash
# Confirms clone-audit-configmap has generateExisting and audit-config exists in
# ops-prod and in the pre-existing ops-legacy namespace, with non-empty data.
set -u

P="clone-audit-configmap"
if ! kubectl get clusterpolicy "$P" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $P not found"
  exit 1
fi

top=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.generateExisting}' 2>/dev/null)
rule=$(kubectl get clusterpolicy "$P" -o jsonpath='{.spec.rules[*].generate.generateExisting}' 2>/dev/null)
if [[ "$top" != "true" && "$rule" != *true* ]]; then
  echo "FAIL: $P does not set generateExisting: true"
  exit 1
fi

for ns in ops-prod ops-legacy; do
  found=""
  for i in $(seq 1 45); do
    found=$(kubectl get configmap audit-config -n "$ns" -o jsonpath='{.data}' 2>/dev/null)
    [[ -n "$found" ]] && break
    sleep 2
  done
  if [[ -z "$found" ]]; then
    echo "FAIL: audit-config ConfigMap with data not found in $ns"
    exit 1
  fi
done

for ns in kube-system kyverno; do
  if kubectl get configmap audit-config -n "$ns" >/dev/null 2>&1; then
    echo "FAIL: audit-config exists in system namespace $ns - exclude it from the rule"
    exit 1
  fi
done

echo "PASS: audit-config was generated into ops-prod and the pre-existing ops-legacy, not into system namespaces."
exit 0
