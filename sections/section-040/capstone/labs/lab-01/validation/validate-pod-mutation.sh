#!/usr/bin/env bash
# Check: pods in an onboarding namespace get the default cost-center label from
# a mutate rule, keep an explicit one, and pods in other namespaces are not
# touched. Reads STORED pods.
set -u

STAMP="$(date +%s)"
PLAIN="chk-plain-$STAMP"
EXPLICIT="chk-explicit-$STAMP"
OTHER="chk-other-$STAMP"
trap 'kubectl delete pod "$PLAIN" "$EXPLICIT" -n shipyard --now --wait=false --ignore-not-found >/dev/null 2>&1; kubectl delete pod "$OTHER" -n default --now --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy workload-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy workload-defaults not found"
  exit 1
fi
if [ -z "$(kubectl get clusterpolicy workload-defaults -o jsonpath='{.spec.rules[*].mutate.patchStrategicMerge}' 2>/dev/null)" ]; then
  echo "FAIL: workload-defaults has no rule that uses mutate.patchStrategicMerge"
  exit 1
fi

value=""
for i in $(seq 1 12); do
  if kubectl run "$PLAIN" --image=registry.k8s.io/pause:3.9 -n shipyard >/dev/null 2>&1; then
    value="$(kubectl get pod "$PLAIN" -n shipyard -o jsonpath='{.metadata.labels.cost-center}' 2>/dev/null || true)"
    [ -n "$value" ] && break
    kubectl delete pod "$PLAIN" -n shipyard --now --wait=true --ignore-not-found >/dev/null 2>&1
  fi
  sleep 5
done
if [ "$value" != "shared" ]; then
  echo "FAIL: a pod without a cost-center label was stored with cost-center='$value', expected shared (it must be admitted, with the label added)"
  exit 1
fi
echo "PASS: a pod without a cost-center label is admitted with cost-center=shared"

if ! kubectl run "$EXPLICIT" --image=registry.k8s.io/pause:3.9 -n shipyard --labels=cost-center=finance >/dev/null 2>&1; then
  echo "FAIL: a pod with an explicit cost-center label was rejected"
  exit 1
fi
value2="$(kubectl get pod "$EXPLICIT" -n shipyard -o jsonpath='{.metadata.labels.cost-center}')"
if [ "$value2" != "finance" ]; then
  echo "FAIL: an explicit cost-center was overwritten with '$value2'; use the +() anchor"
  exit 1
fi
echo "PASS: an explicit cost-center label is kept"

if ! kubectl run "$OTHER" --image=registry.k8s.io/pause:3.9 -n default >/dev/null 2>&1; then
  echo "FAIL: a pod in the default namespace was rejected; the policies must only apply to onboarding namespaces"
  exit 1
fi
if [ -n "$(kubectl get pod "$OTHER" -n default -o jsonpath='{.metadata.labels.cost-center}')" ]; then
  echo "FAIL: a pod in the default namespace got a cost-center label; use a namespaceSelector for onboarding=true"
  exit 1
fi
echo "PASS: pods outside onboarding namespaces are not changed"
exit 0
