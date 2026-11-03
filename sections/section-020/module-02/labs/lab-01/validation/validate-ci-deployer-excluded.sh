#!/usr/bin/env bash
# The ci-deployer ServiceAccount is excluded; its identity bypasses the rule.
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
  echo "FAIL: the policy is not rejecting frontend Pods for the default identity yet, so the exclude cannot be judged"
  exit 1
fi
if out=$(probe_pod "probe-ci-$$" frontend nginx ci-deployer); then
  echo "PASS: a frontend Pod with image nginx is admitted when requested by ci-deployer (excluded subject)"
  exit 0
fi
echo "FAIL: ci-deployer was not excluded: $out"
exit 1
