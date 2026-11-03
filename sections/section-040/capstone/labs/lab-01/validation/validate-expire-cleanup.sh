#!/usr/bin/env bash
# Check: the ClusterCleanupPolicy deletes ConfigMaps in shipyard labelled
# ttl-expired=true and keeps the rest. Creates its own test ConfigMaps.
set -u

POLICY=expire-shipyard-configmaps
STAMP="$(date +%s)"
GONE="chk-expired-$STAMP"
KEEP="chk-keep-$STAMP"
trap 'kubectl delete configmap "$GONE" "$KEEP" -n shipyard --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clustercleanuppolicy "$POLICY" >/dev/null 2>&1; then
  echo "FAIL: ClusterCleanupPolicy $POLICY not found"
  exit 1
fi
schedule="$(kubectl get clustercleanuppolicy "$POLICY" -o jsonpath='{.spec.schedule}')"
case "$schedule" in
  "* * * * *"|"*/1 * * * *"|"*/2 * * * *") echo "PASS: the schedule is '$schedule'" ;;
  *) echo "FAIL: schedule is '$schedule'; use \"* * * * *\""; exit 1 ;;
esac

kubectl create configmap "$GONE" -n shipyard --from-literal=k=v >/dev/null
kubectl label configmap "$GONE" -n shipyard ttl-expired=true >/dev/null
kubectl create configmap "$KEEP" -n shipyard --from-literal=k=v >/dev/null

deleted=0
for i in $(seq 1 80); do
  if ! kubectl get configmap "$GONE" -n shipyard >/dev/null 2>&1; then
    deleted=1
    break
  fi
  sleep 3
done
if [ "$deleted" -ne 1 ]; then
  echo "FAIL: the ConfigMap labelled ttl-expired=true was not deleted within 240 seconds (check the cleanup controller RBAC and kubectl describe clustercleanuppolicy $POLICY)"
  exit 1
fi
echo "PASS: a ConfigMap labelled ttl-expired=true was deleted by the policy"

if ! kubectl get configmap "$KEEP" -n shipyard >/dev/null 2>&1 || ! kubectl get configmap shipyard-notes -n shipyard >/dev/null 2>&1; then
  echo "FAIL: a ConfigMap without ttl-expired=true was deleted; the condition must match only ttl-expired=true"
  exit 1
fi
echo "PASS: ConfigMaps without the label are kept"
exit 0
