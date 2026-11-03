#!/usr/bin/env bash
# Check: a NEW namespace with fleet-managed=true gets a ResourceQuota, a
# NetworkPolicy and a cloned ConfigMap; a namespace without the label gets
# nothing. Uses throwaway namespaces with unique names, removed at the end.
set -u

STAMP="$(date +%s)"
GEN="lab-check-gen-$STAMP"
PLAIN="lab-check-plain-$STAMP"
trap 'kubectl delete namespace "$GEN" "$PLAIN" --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy namespace-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy namespace-defaults not found"
  exit 1
fi

# Give the webhook a moment to pick up a policy that was applied just before submit.
sleep 5
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: $GEN
  labels:
    fleet-managed: "true"
---
apiVersion: v1
kind: Namespace
metadata:
  name: $PLAIN
YAML

found=0
for i in $(seq 1 45); do
  if kubectl get resourcequota default-quota -n "$GEN" >/dev/null 2>&1 \
     && kubectl get networkpolicy default-deny-ingress -n "$GEN" >/dev/null 2>&1 \
     && kubectl get configmap fleet-banner -n "$GEN" >/dev/null 2>&1; then
    found=1
    break
  fi
  sleep 2
done
if [ "$found" -ne 1 ]; then
  echo "FAIL: after 90 seconds the new namespace $GEN is missing default-quota, default-deny-ingress or fleet-banner (run: kubectl get updaterequests -n kyverno)"
  exit 1
fi
echo "PASS: the new namespace got default-quota, default-deny-ingress and fleet-banner"

pods="$(kubectl get resourcequota default-quota -n "$GEN" -o jsonpath='{.spec.hard.pods}')"
if [ "$pods" != "10" ]; then
  echo "FAIL: default-quota has spec.hard.pods='$pods', expected 10"
  exit 1
fi
echo "PASS: default-quota limits pods to 10"

ptype="$(kubectl get networkpolicy default-deny-ingress -n "$GEN" -o jsonpath='{.spec.policyTypes[0]}')"
if [ "$ptype" != "Ingress" ]; then
  echo "FAIL: default-deny-ingress has policyTypes[0]='$ptype', expected Ingress"
  exit 1
fi
if [ -n "$(kubectl get networkpolicy default-deny-ingress -n "$GEN" -o jsonpath='{.spec.ingress}')" ]; then
  echo "FAIL: default-deny-ingress must have no ingress rules"
  exit 1
fi
echo "PASS: default-deny-ingress denies all ingress"

msg="$(kubectl get configmap fleet-banner -n "$GEN" -o jsonpath='{.data.message}')"
if [ "$msg" != "Welcome aboard" ]; then
  echo "FAIL: the cloned fleet-banner has message='$msg', expected the source value 'Welcome aboard'"
  exit 1
fi
echo "PASS: fleet-banner was cloned from fleet-system"

if kubectl get resourcequota default-quota -n "$PLAIN" >/dev/null 2>&1; then
  echo "FAIL: a namespace without the fleet-managed label also got default-quota"
  exit 1
fi
echo "PASS: a namespace without the label gets nothing"
exit 0
