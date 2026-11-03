#!/usr/bin/env bash
# Check: require-pod-standards is an Enforce policy that requires a team label,
# and a pod WITHOUT a team label is still admitted, because the mutate rule adds
# the label before the validate rule runs.
set -u

NS=starfleet
NAME="chk-order-$(date +%s)"
trap 'kubectl delete pod "$NAME" -n "$NS" --now --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy require-pod-standards >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy require-pod-standards not found"
  exit 1
fi
action="$(kubectl get clusterpolicy require-pod-standards -o jsonpath='{.spec.validationFailureAction}')"
case "$action" in
  Enforce|enforce) ;;
  *) echo "FAIL: require-pod-standards has validationFailureAction='$action', expected Enforce"; exit 1 ;;
esac
pattern="$(kubectl get clusterpolicy require-pod-standards -o jsonpath='{.spec.rules[*].validate.pattern.metadata.labels.team}' 2>/dev/null || true)"
if [ -z "$pattern" ]; then
  echo "FAIL: require-pod-standards has no validate.pattern that requires metadata.labels.team"
  exit 1
fi
echo "PASS: require-pod-standards enforces a team label pattern"

admitted=0
for i in $(seq 1 12); do
  if kubectl run "$NAME" --image=registry.k8s.io/pause:3.9 -n "$NS" >/dev/null 2>&1; then
    team="$(kubectl get pod "$NAME" -n "$NS" -o jsonpath='{.metadata.labels.team}' 2>/dev/null || true)"
    if [ -n "$team" ]; then
      admitted=1
      break
    fi
    kubectl delete pod "$NAME" -n "$NS" --now --wait=true --ignore-not-found >/dev/null 2>&1
  fi
  sleep 5
done
if [ "$admitted" -ne 1 ]; then
  echo "FAIL: a pod without a team label was rejected or stored without one; the mutate rule must run first and add the label"
  exit 1
fi
echo "PASS: a pod without a team label is admitted and stored with team=$team"
exit 0
