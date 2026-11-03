#!/usr/bin/env bash
# Check: the proven policy require-team-label is applied to the cluster, is
# Ready, and the admission webhook rejects a Pod without a team label.
set -u
M="${HOME}/kyverno-lab/m1"
fail=0

ready=""
for i in $(seq 1 30); do
  ready="$(kubectl get clusterpolicy require-team-label -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [ "$ready" = "True" ] && break
  sleep 2
done
if [ "$ready" != "True" ]; then
  echo "FAIL: ClusterPolicy require-team-label is not applied and Ready in the cluster"
  exit 1
fi
echo "PASS: ClusterPolicy require-team-label is Ready"

action="$(kubectl get clusterpolicy require-team-label -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null || true)"
if [ "$action" != "Enforce" ]; then
  echo "FAIL: the live policy has validationFailureAction '${action}', expected Enforce"; fail=1
fi

if kubectl apply --dry-run=server -f "${M}/resources/pod-nolabel.yaml" >/dev/null 2>&1; then
  echo "FAIL: the cluster admitted web-nolabel; the policy should reject it"; fail=1
else
  echo "PASS: the cluster rejects web-nolabel"
fi

if kubectl apply --dry-run=server -f "${M}/resources/pod-good.yaml" >/dev/null 2>&1; then
  echo "PASS: the cluster admits web-good"
else
  echo "FAIL: the cluster rejected web-good"; fail=1
fi
exit "$fail"
