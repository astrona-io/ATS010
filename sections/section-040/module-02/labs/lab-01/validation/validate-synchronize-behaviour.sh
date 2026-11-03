#!/usr/bin/env bash
# Check: synchronize is true for the quota and the NetworkPolicy and false for
# the cloned ConfigMap, and the cluster behaves that way: a deleted NetworkPolicy
# comes back, an edited quota is restored, an edited clone keeps its edit.
set -u

STAMP="$(date +%s)"
NS="lab-check-sync-$STAMP"
trap 'kubectl delete namespace "$NS" --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy namespace-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy namespace-defaults not found"
  exit 1
fi
sync_of() {
  kubectl get clusterpolicy namespace-defaults -o jsonpath="{.spec.rules[?(@.generate.kind==\"$1\")].generate.synchronize}" 2>/dev/null
}
if [ "$(sync_of ResourceQuota)" != "true" ] || [ "$(sync_of NetworkPolicy)" != "true" ]; then
  echo "FAIL: the ResourceQuota and NetworkPolicy rules must set synchronize: true"
  exit 1
fi
if [ "$(sync_of ConfigMap)" != "false" ]; then
  echo "FAIL: the ConfigMap clone rule must set synchronize: false"
  exit 1
fi
echo "PASS: synchronize is true for quota and NetworkPolicy and false for the clone"

sleep 5
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: $NS
  labels:
    fleet-managed: "true"
YAML

found=0
for i in $(seq 1 45); do
  if kubectl get resourcequota default-quota -n "$NS" >/dev/null 2>&1 \
     && kubectl get networkpolicy default-deny-ingress -n "$NS" >/dev/null 2>&1 \
     && kubectl get configmap fleet-banner -n "$NS" >/dev/null 2>&1; then
    found=1
    break
  fi
  sleep 2
done
if [ "$found" -ne 1 ]; then
  echo "FAIL: the new namespace did not get its generated resources, so synchronize cannot be tested"
  exit 1
fi

kubectl delete networkpolicy default-deny-ingress -n "$NS" >/dev/null 2>&1
back=0
for i in $(seq 1 45); do
  if kubectl get networkpolicy default-deny-ingress -n "$NS" >/dev/null 2>&1; then
    back=1
    break
  fi
  sleep 2
done
if [ "$back" -ne 1 ]; then
  echo "FAIL: a deleted NetworkPolicy was not recreated within 90 seconds (synchronize: true expected)"
  exit 1
fi
echo "PASS: a deleted NetworkPolicy is recreated"

kubectl patch resourcequota default-quota -n "$NS" --type merge -p '{"spec":{"hard":{"pods":"99"}}}' >/dev/null 2>&1
restored=0
for i in $(seq 1 45); do
  if [ "$(kubectl get resourcequota default-quota -n "$NS" -o jsonpath='{.spec.hard.pods}' 2>/dev/null)" = "10" ]; then
    restored=1
    break
  fi
  sleep 2
done
if [ "$restored" -ne 1 ]; then
  echo "FAIL: an edited ResourceQuota was not restored to pods=10 within 90 seconds"
  exit 1
fi
echo "PASS: an edited ResourceQuota is restored"

kubectl patch configmap fleet-banner -n "$NS" --type merge -p '{"data":{"message":"edited by hand"}}' >/dev/null 2>&1
sleep 20
if [ "$(kubectl get configmap fleet-banner -n "$NS" -o jsonpath='{.data.message}' 2>/dev/null)" != "edited by hand" ]; then
  echo "FAIL: the edit of the cloned ConfigMap was reverted (synchronize: false expected)"
  exit 1
fi
echo "PASS: an edited clone keeps its edit"
exit 0
