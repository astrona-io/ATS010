#!/usr/bin/env bash
# The ClusterPolicy exists, is Enforce, uses a selector, operations and a
# ci-deployer exclude, and disables background scans (identity fields only
# exist on admission requests).
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

json=$(kubectl get clusterpolicy "$POLICY" -o json 2>/dev/null)
if [[ -z "$json" ]]; then
  echo "FAIL: ClusterPolicy $POLICY not found"
  exit 1
fi
action=$(echo "$json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: validationFailureAction is '$action', expected Enforce"
  exit 1
fi
if ! echo "$json" | grep -q '"selector"'; then
  echo "FAIL: the rule does not use selector (labels on the Pod itself)"
  exit 1
fi
if ! echo "$json" | grep -q '"CREATE"'; then
  echo "FAIL: the rule does not set operations: [CREATE]"
  exit 1
fi
if ! echo "$json" | grep -q 'ci-deployer'; then
  echo "FAIL: the policy does not exclude the ci-deployer ServiceAccount"
  exit 1
fi
bg=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.background}' 2>/dev/null)
if [[ "$bg" == "true" ]]; then
  echo "FAIL: spec.background is true; a policy that selects by subjects must set background: false"
  exit 1
fi
echo "PASS: $POLICY is Enforce with selector, operations CREATE and a ci-deployer exclude"
exit 0
