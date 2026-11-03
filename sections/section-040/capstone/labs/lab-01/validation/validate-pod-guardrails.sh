#!/usr/bin/env bash
# Check: workload-guardrails is an Enforce policy that requires a cost-center
# label (satisfied by the mutation) and rejects pods that use the host network.
set -u

NS=shipyard
STAMP="$(date +%s)"
BAD="chk-hostnet-$STAMP"
GOOD="chk-good-$STAMP"
trap 'kubectl delete pod "$BAD" "$GOOD" -n "$NS" --now --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy workload-guardrails >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy workload-guardrails not found"
  exit 1
fi
action="$(kubectl get clusterpolicy workload-guardrails -o jsonpath='{.spec.validationFailureAction}')"
case "$action" in
  Enforce|enforce) ;;
  *) echo "FAIL: workload-guardrails has validationFailureAction='$action', expected Enforce"; exit 1 ;;
esac
if [ -z "$(kubectl get clusterpolicy workload-guardrails -o jsonpath='{.spec.rules[*].validate.pattern.metadata.labels.cost-center}' 2>/dev/null)" ]; then
  echo "FAIL: workload-guardrails has no validate.pattern that requires metadata.labels.cost-center"
  exit 1
fi
echo "PASS: workload-guardrails enforces a cost-center label pattern"

rejected=0
output=""
for i in $(seq 1 12); do
  if output="$(kubectl apply -f - 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $BAD
  namespace: $NS
spec:
  hostNetwork: true
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
YAML
)"; then
    kubectl delete pod "$BAD" -n "$NS" --now --wait=true --ignore-not-found >/dev/null 2>&1
    sleep 5
  else
    rejected=1
    break
  fi
done
if [ "$rejected" -ne 1 ]; then
  echo "FAIL: a pod with hostNetwork: true was admitted"
  exit 1
fi
if ! echo "$output" | grep -q "workload-guardrails"; then
  echo "FAIL: the pod was rejected, but not by workload-guardrails: $output"
  exit 1
fi
echo "PASS: a pod with hostNetwork: true is rejected by workload-guardrails"

if ! kubectl run "$GOOD" --image=registry.k8s.io/pause:3.9 -n "$NS" >/dev/null 2>&1; then
  echo "FAIL: a normal pod without labels was rejected; the mutate rule must add cost-center before validation"
  exit 1
fi
echo "PASS: a normal pod is admitted (mutation runs before validation)"
exit 0
