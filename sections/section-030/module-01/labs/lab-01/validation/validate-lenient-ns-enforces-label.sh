#!/usr/bin/env bash
# Confirms lenient-ns rejects a Pod with no app label (server-side dry run), and that
# the labelled has-app-pod exists there, while no-app-pod does not.
set -u

NS="lenient-ns"

# Wait for the webhook to know the policy: the unlabelled dry run must be denied.
denied=0
for i in $(seq 1 30); do
  if ! kubectl apply --dry-run=server -n "$NS" -f - >/dev/null 2>&1 <<POD
apiVersion: v1
kind: Pod
metadata:
  name: validation-probe
spec:
  containers:
    - name: c
      image: nginx:alpine
POD
  then
    denied=1
    break
  fi
  sleep 2
done
if [[ "$denied" != "1" ]]; then
  echo "FAIL: a Pod with no app label was not rejected in $NS"
  exit 1
fi

if kubectl get pod no-app-pod -n "$NS" >/dev/null 2>&1; then
  echo "FAIL: no-app-pod exists in $NS - it should have been blocked by the policy"
  exit 1
fi

app=$(kubectl get pod has-app-pod -n "$NS" -o jsonpath='{.metadata.labels.app}' 2>/dev/null)
if [[ "$app" != "checkout" ]]; then
  echo "FAIL: has-app-pod missing in $NS or its app label is '$app', expected checkout"
  exit 1
fi

echo "PASS: $NS rejects Pods without an app label and has-app-pod (app=checkout) was admitted."
exit 0
