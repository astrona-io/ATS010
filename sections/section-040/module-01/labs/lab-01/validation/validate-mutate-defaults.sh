#!/usr/bin/env bash
# Check: pod-defaults uses patchStrategicMerge to add a default team label and a
# default allowPrivilegeEscalation, without overwriting what the author set.
# Reads the STORED pods, never the YAML that was applied.
set -u

NS=starfleet
STAMP="$(date +%s)"
PLAIN="chk-plain-$STAMP"
EXPLICIT="chk-explicit-$STAMP"
cleanup() { kubectl delete pod "$PLAIN" "$EXPLICIT" -n "$NS" --now --wait=false --ignore-not-found >/dev/null 2>&1; }
trap cleanup EXIT

if ! kubectl get clusterpolicy pod-defaults >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy pod-defaults not found"
  exit 1
fi
if [ -z "$(kubectl get clusterpolicy pod-defaults -o jsonpath='{.spec.rules[*].mutate.patchStrategicMerge}' 2>/dev/null)" ]; then
  echo "FAIL: pod-defaults has no rule that uses mutate.patchStrategicMerge"
  exit 1
fi

# The webhook can need a few seconds to pick up a new policy, so retry the plain pod.
team=""
for i in $(seq 1 12); do
  kubectl apply -f - >/dev/null 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $PLAIN
  namespace: $NS
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
YAML
  team="$(kubectl get pod "$PLAIN" -n "$NS" -o jsonpath='{.metadata.labels.team}' 2>/dev/null || true)"
  [ -n "$team" ] && break
  kubectl delete pod "$PLAIN" -n "$NS" --now --wait=true --ignore-not-found >/dev/null 2>&1
  sleep 5
done
if [ "$team" != "platform" ]; then
  echo "FAIL: a pod without labels was stored with team='$team', expected team=platform"
  exit 1
fi
echo "PASS: a pod without a team label is stored with team=platform"

ape="$(kubectl get pod "$PLAIN" -n "$NS" -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null || true)"
if [ "$ape" != "false" ]; then
  echo "FAIL: the stored container has allowPrivilegeEscalation='$ape', expected false"
  exit 1
fi
echo "PASS: the stored container has allowPrivilegeEscalation=false"

if ! kubectl apply -f - >/dev/null 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $EXPLICIT
  namespace: $NS
  labels:
    team: ops
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
      securityContext:
        allowPrivilegeEscalation: true
YAML
then
  echo "FAIL: a pod that sets its own team label and securityContext was rejected"
  exit 1
fi
team2="$(kubectl get pod "$EXPLICIT" -n "$NS" -o jsonpath='{.metadata.labels.team}')"
ape2="$(kubectl get pod "$EXPLICIT" -n "$NS" -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')"
if [ "$team2" != "ops" ] || [ "$ape2" != "true" ]; then
  echo "FAIL: explicit values were overwritten (team='$team2', allowPrivilegeEscalation='$ape2'); use the +() add-if-not-present anchor"
  exit 1
fi
echo "PASS: explicit values are kept (team=ops, allowPrivilegeEscalation=true)"
exit 0
