#!/usr/bin/env bash
# Check: a rule with mutate.patchesJson6902 sets automountServiceAccountToken to
# false on the stored pod, even when the author wrote true.
set -u

NS=starfleet
NAME="chk-json-$(date +%s)"
trap 'kubectl delete pod "$NAME" -n "$NS" --now --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy pod-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy pod-defaults not found"
  exit 1
fi
if [ -z "$(kubectl get clusterpolicy pod-defaults -o jsonpath='{.spec.rules[*].mutate.patchesJson6902}' 2>/dev/null)" ]; then
  echo "FAIL: pod-defaults has no rule that uses mutate.patchesJson6902"
  exit 1
fi
echo "PASS: pod-defaults has a patchesJson6902 rule"

value=""
for i in $(seq 1 12); do
  kubectl apply -f - >/dev/null 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $NAME
  namespace: $NS
spec:
  automountServiceAccountToken: true
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
YAML
  value="$(kubectl get pod "$NAME" -n "$NS" -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null || true)"
  [ "$value" = "false" ] && break
  kubectl delete pod "$NAME" -n "$NS" --now --wait=true --ignore-not-found >/dev/null 2>&1
  sleep 5
done
if [ "$value" != "false" ]; then
  echo "FAIL: the stored pod has automountServiceAccountToken='$value', expected false"
  exit 1
fi
echo "PASS: the stored pod has automountServiceAccountToken=false"
exit 0
