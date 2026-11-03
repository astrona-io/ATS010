#!/usr/bin/env bash
# Confirms clone-default-netpol has generateExisting set and that it backfilled
# a default-deny-ingress NetworkPolicy into the namespaces that existed before
# it, and not into system namespaces.
set -u

POLICY="clone-default-netpol"

if ! kubectl get clusterpolicy "$POLICY" >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy $POLICY not found"
  exit 1
fi

# Accept the policy-level field or the rule-level one.
top=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.generateExisting}' 2>/dev/null)
rule=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.rules[*].generate.generateExisting}' 2>/dev/null)
if [[ "$top" != "true" && "$rule" != *true* ]]; then
  echo "FAIL: $POLICY does not set generateExisting: true"
  exit 1
fi

# The backfill is asynchronous: poll for it.
missing=""
for i in $(seq 1 45); do
  missing=""
  for ns in team-a team-b team-c; do
    kubectl get networkpolicy default-deny-ingress -n "$ns" >/dev/null 2>&1 || missing="$missing $ns"
  done
  [[ -z "$missing" ]] && break
  sleep 2
done
if [[ -n "$missing" ]]; then
  echo "FAIL: default-deny-ingress was not backfilled into:$missing (they existed before the policy)"
  exit 1
fi

for ns in team-a team-b team-c; do
  ptypes=$(kubectl get networkpolicy default-deny-ingress -n "$ns" -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)
  sel=$(kubectl get networkpolicy default-deny-ingress -n "$ns" -o jsonpath='{.spec.podSelector}' 2>/dev/null)
  ingress=$(kubectl get networkpolicy default-deny-ingress -n "$ns" -o jsonpath='{.spec.ingress}' 2>/dev/null)
  if [[ "$ptypes" != "Ingress" || "$sel" != "{}" || -n "$ingress" ]]; then
    echo "FAIL: default-deny-ingress in $ns is not a default-deny (policyTypes='$ptypes', podSelector='$sel', ingress='$ingress')"
    exit 1
  fi
done

for ns in kube-system kyverno kube-node-lease kube-public; do
  if kubectl get networkpolicy default-deny-ingress -n "$ns" >/dev/null 2>&1; then
    echo "FAIL: default-deny-ingress exists in system namespace $ns - exclude it from the rule"
    exit 1
  fi
done

echo "PASS: generateExisting backfilled default-deny-ingress into team-a, team-b and team-c, and system namespaces were skipped."
exit 0
