#!/usr/bin/env bash
# A tier=frontend Pod with image nginx is rejected for the default identity,
# and a frontend Pod with an allowed image is admitted.
set -u

POLICY="restrict-frontend-images"
NS="apps-ns"

# Server-side dry-run of a Pod create. Args: name tier image [serviceaccount-to-impersonate]
probe_pod() {
  local as=()
  [[ -n "${4:-}" ]] && as=(--as="system:serviceaccount:${NS}:$4")
  kubectl ${as[@]+"${as[@]}"} run "$1" --image="$3" -n "$NS" --labels="tier=$2" --dry-run=server -o name 2>&1
}

# Poll until a frontend Pod with a bad image is rejected by the policy.
wait_blocked() {
  local out i
  for i in $(seq 1 30); do
    out=$(probe_pod "probe-gate-$$" frontend nginx) && { sleep 2; continue; }
    if echo "$out" | grep -q "$POLICY"; then
      return 0
    fi
    sleep 2
  done
  echo "$out"
  return 1
}

if ! wait_blocked; then
  echo "FAIL: a tier=frontend Pod with image nginx in $NS was not rejected by $POLICY"
  exit 1
fi
if ! out=$(probe_pod "probe-good-$$" frontend "registry.internal/nginx"); then
  echo "FAIL: a frontend Pod with image registry.internal/nginx was rejected: $out"
  exit 1
fi
echo "PASS: frontend Pods with a bad image are rejected, and registry.internal/* images are admitted"
exit 0
