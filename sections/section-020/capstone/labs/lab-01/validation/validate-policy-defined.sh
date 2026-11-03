#!/usr/bin/env bash
# The ClusterPolicy exists, is Enforce, and uses every selection axis.
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
for needle in '"Deployment"' 'release-\*' '"namespaceSelector"' '"selector"' '"CREATE"' '"UPDATE"' 'release-bot'; do
  if ! echo "$json" | grep -q "$needle"; then
    echo "FAIL: the policy does not contain $needle (kinds, names, namespaceSelector, selector, operations CREATE and UPDATE, release-bot exclude)"
    exit 1
  fi
done
bg=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.spec.background}' 2>/dev/null)
if [[ "$bg" == "true" ]]; then
  echo "FAIL: spec.background is true; a policy that selects by subjects must set background: false"
  exit 1
fi
echo "PASS: $POLICY is Enforce and uses kinds, names, namespaceSelector, selector, operations and a release-bot exclude"
exit 0
