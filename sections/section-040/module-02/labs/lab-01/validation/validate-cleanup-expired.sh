#!/usr/bin/env bash
# Check: the ClusterCleanupPolicy runs on a short schedule and deletes only
# ConfigMaps in scratch that are labelled expired=true. Creates its own test
# ConfigMaps, so it can run any number of times.
set -u

POLICY=remove-expired-configmaps
STAMP="$(date +%s)"
GONE="chk-expired-$STAMP"
KEEP="chk-keep-$STAMP"
trap 'kubectl delete configmap "$GONE" "$KEEP" -n scratch --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clustercleanuppolicy "$POLICY" >/dev/null 2>&1; then
  echo "FAIL: ClusterCleanupPolicy $POLICY not found"
  exit 1
fi
schedule="$(kubectl get clustercleanuppolicy "$POLICY" -o jsonpath='{.spec.schedule}')"
case "$schedule" in
  "* * * * *"|"*/1 * * * *"|"*/2 * * * *") echo "PASS: the schedule is '$schedule'" ;;
  *) echo "FAIL: schedule is '$schedule'; use \"* * * * *\" so the check does not wait long"; exit 1 ;;
esac

if ! kubectl get configmap keep-report -n scratch >/dev/null 2>&1; then
  echo "FAIL: keep-report (expired=false) was deleted; the condition must only match expired=true"
  exit 1
fi
echo "PASS: keep-report still exists"

kubectl create configmap "$GONE" -n scratch --from-literal=k=v >/dev/null
kubectl label configmap "$GONE" -n scratch expired=true >/dev/null
kubectl create configmap "$KEEP" -n scratch --from-literal=k=v >/dev/null
kubectl label configmap "$KEEP" -n scratch expired=false >/dev/null

deleted=0
for i in $(seq 1 80); do
  if ! kubectl get configmap "$GONE" -n scratch >/dev/null 2>&1; then
    deleted=1
    break
  fi
  sleep 3
done
if [ "$deleted" -ne 1 ]; then
  echo "FAIL: the ConfigMap labelled expired=true was not deleted within 240 seconds (check the cleanup controller RBAC and kubectl describe clustercleanuppolicy $POLICY)"
  exit 1
fi
echo "PASS: a ConfigMap labelled expired=true was deleted by the policy"

if ! kubectl get configmap "$KEEP" -n scratch >/dev/null 2>&1; then
  echo "FAIL: a ConfigMap labelled expired=false was deleted"
  exit 1
fi
if ! kubectl get configmap keep-report -n scratch >/dev/null 2>&1; then
  echo "FAIL: keep-report was deleted"
  exit 1
fi
echo "PASS: ConfigMaps labelled expired=false are kept"
exit 0
