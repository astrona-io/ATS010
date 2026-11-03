#!/usr/bin/env bash
# Check: the Kyverno background controller may create the generated kinds, and
# the cleanup controller may delete ConfigMaps. Asks the API server with can-i.
set -u

bg="system:serviceaccount:kyverno:kyverno-background-controller"
cl="system:serviceaccount:kyverno:kyverno-cleanup-controller"
fail=0

for resource in networkpolicies resourcequotas configmaps; do
  answer=""
  for i in $(seq 1 15); do
    answer="$(kubectl auth can-i create "$resource" --as="$bg" 2>/dev/null || true)"
    [ "$answer" = "yes" ] && break
    sleep 2
  done
  if [ "$answer" = "yes" ]; then
    echo "PASS: the background controller can create $resource"
  else
    echo "FAIL: the background controller cannot create $resource (add a ClusterRole labelled rbac.kyverno.io/aggregate-to-background-controller: \"true\")"
    fail=1
  fi
done

answer=""
for i in $(seq 1 15); do
  answer="$(kubectl auth can-i delete configmaps --as="$cl" 2>/dev/null || true)"
  [ "$answer" = "yes" ] && break
  sleep 2
done
if [ "$answer" = "yes" ]; then
  echo "PASS: the cleanup controller can delete configmaps"
else
  echo "FAIL: the cleanup controller cannot delete configmaps (add a ClusterRole labelled rbac.kyverno.io/aggregate-to-cleanup-controller: \"true\")"
  fail=1
fi
exit "$fail"
