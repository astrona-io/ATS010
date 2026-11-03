#!/usr/bin/env bash
# Each axis independently takes a request out of scope: name, namespace, label.
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
  echo "FAIL: the policy is not active yet, so scope cannot be judged"
  exit 1
fi
fail=0
if ! out=$(probe_deploy "web-$$" store-prod stable); then
  echo "FAIL: web-* in store-prod was rejected, but only release-* names are in scope: $out"
  fail=1
fi
if ! out=$(probe_deploy "release-dev-$$" store-dev stable); then
  echo "FAIL: release-* in store-dev (env=dev) was rejected, but only env=prod namespaces are in scope: $out"
  fail=1
fi
if ! out=$(probe_deploy "release-beta-$$" store-prod beta); then
  echo "FAIL: channel=beta was rejected, but only channel=stable is in scope: $out"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: name, namespaceSelector and selector each independently take a request out of scope"
  exit 0
fi
exit 1
