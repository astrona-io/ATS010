#!/usr/bin/env bash
# Check: a pod that uses an image with the latest tag is rejected by
# require-pod-standards, and a pod with a pinned tag is admitted.
set -u

NS=starfleet
STAMP="$(date +%s)"
BAD="chk-latest-$STAMP"
GOOD="chk-pinned-$STAMP"
trap 'kubectl delete pod "$BAD" "$GOOD" -n "$NS" --now --wait=false --ignore-not-found >/dev/null 2>&1' EXIT

if ! kubectl get clusterpolicy require-pod-standards >/dev/null 2>&1; then
  echo "FAIL: ClusterPolicy require-pod-standards not found"
  exit 1
fi

rejected=0
output=""
for i in $(seq 1 12); do
  if output="$(kubectl run "$BAD" --image=registry.k8s.io/pause:latest -n "$NS" 2>&1)"; then
    # Admitted: the webhook may not have the new rule yet. Remove the pod and retry.
    kubectl delete pod "$BAD" -n "$NS" --now --wait=true --ignore-not-found >/dev/null 2>&1
    sleep 5
  else
    rejected=1
    break
  fi
done
if [ "$rejected" -ne 1 ]; then
  echo "FAIL: a pod with image pause:latest was admitted; the policy must reject :latest images"
  exit 1
fi
if ! echo "$output" | grep -q "require-pod-standards"; then
  echo "FAIL: the pod was rejected, but not by require-pod-standards: $output"
  exit 1
fi
echo "PASS: a pod with image pause:latest is rejected by require-pod-standards"

if ! kubectl run "$GOOD" --image=registry.k8s.io/pause:3.9 -n "$NS" >/dev/null 2>&1; then
  echo "FAIL: a pod with the pinned image pause:3.9 was rejected"
  exit 1
fi
echo "PASS: a pod with a pinned image tag is admitted"
exit 0
