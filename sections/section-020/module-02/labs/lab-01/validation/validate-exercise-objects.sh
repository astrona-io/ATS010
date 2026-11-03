#!/usr/bin/env bash
# The objects from the exercise exist or are absent as the question requires.
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

fail=0
if kubectl get pod frontend-pod -n "$NS" >/dev/null 2>&1; then
  echo "FAIL: frontend-pod exists in $NS; it should have been rejected"
  fail=1
fi
for p in ci-pod backend-pod; do
  if ! kubectl get pod "$p" -n "$NS" >/dev/null 2>&1; then
    echo "FAIL: Pod $p is missing from $NS"
    fail=1
  fi
done
ci_label=$(kubectl get pod ci-pod -n "$NS" -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [[ "$ci_label" != "frontend" ]]; then
  echo "FAIL: ci-pod should carry the label tier=frontend (found '$ci_label')"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: frontend-pod absent; ci-pod (tier=frontend) and backend-pod present"
  exit 0
fi
exit 1
