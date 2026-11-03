#!/usr/bin/env bash
# Check: restrict-registry is Ready in the cluster and the admission webhook
# rejects the external image and admits the internal one.
set -u
M="${HOME}/kyverno-lab/capstone"
fail=0

ready=""
for i in $(seq 1 30); do
  ready="$(kubectl get clusterpolicy restrict-registry -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$ready" = "True" ] && break
  sleep 2
done
if [ "$ready" != "True" ]; then
  echo "FAIL: ClusterPolicy restrict-registry is not applied and Ready"
  exit 1
fi
echo "PASS: ClusterPolicy restrict-registry is Ready"

action="$(kubectl get clusterpolicy restrict-registry -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null || true)"
[ "$action" = "Enforce" ] || { echo "FAIL: live action is '${action}', expected Enforce"; fail=1; }

if kubectl apply --dry-run=server -f "${M}/resources/pod-external.yaml" >/dev/null 2>&1; then
  echo "FAIL: the cluster admitted the docker.io image"; fail=1
else
  echo "PASS: the cluster rejects the docker.io image"
fi
if kubectl apply --dry-run=server -f "${M}/resources/pod-internal.yaml" >/dev/null 2>&1; then
  echo "PASS: the cluster admits the ghcr.io/acme image"
else
  echo "FAIL: the cluster rejected the ghcr.io/acme image"; fail=1
fi
exit "$fail"
