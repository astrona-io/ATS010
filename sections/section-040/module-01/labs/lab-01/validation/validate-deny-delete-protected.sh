#!/usr/bin/env bash
# Check: a deny rule blocks DELETE of a ConfigMap labelled protected=true and
# leaves other ConfigMaps alone. Uses --dry-run=server, so nothing is deleted
# and the check can run any number of times.
set -u

NS=starfleet

if ! kubectl get clusterpolicy protect-registry >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy protect-registry not found"
  exit 1
fi
if [ -z "$(kubectl get clusterpolicy protect-registry -o jsonpath='{.spec.rules[*].validate.deny}' 2>/dev/null)" ]; then
  echo "FAIL: protect-registry has no rule that uses validate.deny"
  exit 1
fi
if ! kubectl get configmap fleet-registry -n "$NS" >/dev/null 2>&1; then
  echo "FAIL: ConfigMap fleet-registry is gone; recreate the lab"
  exit 1
fi

rejected=0
output=""
for i in $(seq 1 12); do
  if output="$(kubectl delete configmap fleet-registry -n "$NS" --dry-run=server 2>&1)"; then
    sleep 5
  else
    rejected=1
    break
  fi
done
if [ "$rejected" -ne 1 ]; then
  echo "FAIL: deleting the protected ConfigMap fleet-registry was allowed"
  exit 1
fi
if ! echo "$output" | grep -q "protect-registry"; then
  echo "FAIL: the delete was rejected, but not by protect-registry: $output"
  exit 1
fi
echo "PASS: deleting the protected ConfigMap is rejected by protect-registry"

if ! kubectl delete configmap scratch-notes -n "$NS" --dry-run=server >/dev/null 2>&1; then
  echo "FAIL: deleting the unprotected ConfigMap scratch-notes was rejected; the rule must only block protected=true"
  exit 1
fi
echo "PASS: an unprotected ConfigMap can still be deleted"
exit 0
