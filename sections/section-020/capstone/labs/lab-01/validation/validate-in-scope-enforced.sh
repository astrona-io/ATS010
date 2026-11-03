#!/usr/bin/env bash
# In scope: stable release-* Deployment in an env=prod namespace, normal identity.
# Rejected without approved-by, admitted with it.
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
  echo "FAIL: an unannotated stable release-app Deployment in store-prod was not rejected by $POLICY"
  exit 1
fi
if ! out=$(probe_deploy "release-ok-$$" store-prod stable "" "team-lead"); then
  echo "FAIL: a Deployment with approved-by was rejected: $out"
  exit 1
fi
echo "PASS: unannotated stable release-* Deployments in store-prod are rejected, annotated ones admitted"
exit 0
