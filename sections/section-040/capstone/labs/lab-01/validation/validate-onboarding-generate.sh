#!/usr/bin/env bash
# Check: a NEW namespace labelled onboarding=true gets team-quota (pods 15, kept
# in sync) and default-deny-ingress; an unlabelled namespace gets nothing; the
# generated quota is restored after an edit. Uses throwaway namespaces.
set -u

STAMP="$(date +%s)"
GEN="cap-check-gen-$STAMP"
PLAIN="cap-check-plain-$STAMP"
trap 'kubectl delete namespace "$GEN" "$PLAIN" --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy onboard-namespace >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy onboard-namespace not found"
  exit 1
fi
sleep 5
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: $GEN
  labels:
    onboarding: "true"
---
apiVersion: v1
kind: Namespace
metadata:
  name: $PLAIN
YAML

found=0
for i in $(seq 1 45); do
  if kubectl get resourcequota team-quota -n "$GEN" >/dev/null 2>&1 \
     && kubectl get networkpolicy default-deny-ingress -n "$GEN" >/dev/null 2>&1; then
    found=1
    break
  fi
  sleep 2
done
if [ "$found" -ne 1 ]; then
  echo "FAIL: after 90 seconds the new namespace is missing team-quota or default-deny-ingress (run: kubectl get updaterequests -n kyverno)"
  exit 1
fi
echo "PASS: a new onboarding namespace got team-quota and default-deny-ingress"

pods="$(kubectl get resourcequota team-quota -n "$GEN" -o jsonpath='{.spec.hard.pods}')"
if [ "$pods" != "15" ]; then
  echo "FAIL: team-quota has spec.hard.pods='$pods', expected 15"
  exit 1
fi
ptype="$(kubectl get networkpolicy default-deny-ingress -n "$GEN" -o jsonpath='{.spec.policyTypes[0]}')"
if [ "$ptype" != "Ingress" ] || [ -n "$(kubectl get networkpolicy default-deny-ingress -n "$GEN" -o jsonpath='{.spec.ingress}')" ]; then
  echo "FAIL: default-deny-ingress must have policyTypes Ingress and no ingress rules"
  exit 1
fi
echo "PASS: the generated objects have the required content"

if kubectl get resourcequota team-quota -n "$PLAIN" >/dev/null 2>&1; then
  echo "FAIL: a namespace without the onboarding label also got team-quota"
  exit 1
fi
echo "PASS: a namespace without the label gets nothing"

kubectl patch resourcequota team-quota -n "$GEN" --type merge -p '{"spec":{"hard":{"pods":"99"}}}' >/dev/null 2>&1
restored=0
for i in $(seq 1 45); do
  if [ "$(kubectl get resourcequota team-quota -n "$GEN" -o jsonpath='{.spec.hard.pods}' 2>/dev/null)" = "15" ]; then
    restored=1
    break
  fi
  sleep 2
done
if [ "$restored" -ne 1 ]; then
  echo "FAIL: an edited team-quota was not restored to pods=15 within 90 seconds (synchronize: true expected)"
  exit 1
fi
echo "PASS: an edited team-quota is restored"
exit 0
