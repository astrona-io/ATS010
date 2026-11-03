#!/usr/bin/env bash
# Out-of-scope requests are admitted: other labels, and UPDATE operations.
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
  echo "FAIL: the policy is not rejecting frontend Pods yet, so scope cannot be judged"
  exit 1
fi
fail=0
if ! out=$(probe_pod "probe-backend-$$" backend nginx); then
  echo "FAIL: a tier=backend Pod was rejected, but the selector requires tier=frontend: $out"
  fail=1
fi

# UPDATE is out of scope: relabeling the existing backend-pod into the frontend
# scope must be admitted (dry-run, nothing changes).
if kubectl get pod backend-pod -n "$NS" >/dev/null 2>&1; then
  if ! out=$(kubectl label pod backend-pod tier=frontend --overwrite -n "$NS" --dry-run=server 2>&1); then
    echo "FAIL: relabeling backend-pod (an UPDATE) was rejected, but the rule should only see CREATE: $out"
    fail=1
  fi
else
  echo "FAIL: backend-pod does not exist; create it as step 5 of the question asks"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: tier=backend Pods and UPDATE requests are out of scope and admitted"
  exit 0
fi
exit 1
