#!/usr/bin/env bash
# release-bot is excluded; and UPDATE is in scope (operations include UPDATE).
set -u

POLICY="require-approved-release"

# Server-side dry-run create of a Deployment.
# Args: name namespace channel [serviceaccount-in-store-prod-to-impersonate] [approved-by]
probe_deploy() {
  local name="$1" ns="$2" channel="$3" sa="${4:-}" approved="${5:-}"
  local as=()
  [[ -n "$sa" ]] && as=(--as="system:serviceaccount:store-prod:${sa}")
  local ann=""
  [[ -n "$approved" ]] && ann="  annotations: {approved-by: \"${approved}\"}"
  kubectl ${as[@]+"${as[@]}"} create --dry-run=server -o name -f - 2>&1 <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  namespace: ${ns}
  labels: {channel: ${channel}}
${ann}
spec:
  replicas: 1
  selector:
    matchLabels: {app: ${name}}
  template:
    metadata:
      labels: {app: ${name}}
    spec:
      containers:
        - name: app
          image: nginx
YAML
}

# Poll until a stable release-* Deployment in store-prod is rejected (policy active).
wait_blocked() {
  local out i
  for i in $(seq 1 30); do
    out=$(probe_deploy "release-gate-$$" store-prod stable) && { sleep 2; continue; }
    if echo "$out" | grep -q "$POLICY"; then
      return 0
    fi
    sleep 2
  done
  echo "$out"
  return 1
}

if ! wait_blocked; then
  echo "FAIL: the policy is not active yet, so the exclude cannot be judged"
  exit 1
fi
fail=0
if ! out=$(probe_deploy "release-bot-$$" store-prod stable release-bot); then
  echo "FAIL: release-bot was not excluded: $out"
  fail=1
fi

# UPDATE must be in scope: relabeling the existing beta Deployment into the stable
# channel (no approved-by) must be rejected. Dry-run, so nothing changes.
if kubectl get deployment release-canary -n store-prod >/dev/null 2>&1; then
  out=$(kubectl label deployment release-canary channel=stable --overwrite -n store-prod --dry-run=server 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]] || ! echo "$out" | grep -q "$POLICY"; then
    echo "FAIL: relabeling release-canary into channel=stable (an UPDATE) was not rejected; operations must include UPDATE"
    fail=1
  fi
else
  echo "FAIL: release-canary does not exist in store-prod; create it as step 5 of the question asks"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: release-bot is excluded and UPDATE requests are in scope"
  exit 0
fi
exit 1
