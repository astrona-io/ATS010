#!/usr/bin/env bash
# The objects from the exercise exist in the expected namespaces.
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

fail=0
if ! kubectl get deployment release-app -n store-prod >/dev/null 2>&1; then
  echo "FAIL: release-app missing from store-prod; it should exist via the release-bot exclusion"
  fail=1
else
  ann=$(kubectl get deployment release-app -n store-prod -o jsonpath='{.metadata.annotations.approved-by}' 2>/dev/null)
  if [[ -n "$ann" ]]; then
    echo "FAIL: release-app in store-prod has an approved-by annotation; the exercise creates it without one"
    fail=1
  fi
fi
if ! kubectl get deployment release-canary -n store-prod >/dev/null 2>&1; then
  echo "FAIL: release-canary missing from store-prod"
  fail=1
fi
if ! kubectl get deployment release-app -n store-dev >/dev/null 2>&1; then
  echo "FAIL: release-app missing from store-dev"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: release-app (store-prod and store-dev) and release-canary exist as the question requires"
  exit 0
fi
exit 1
