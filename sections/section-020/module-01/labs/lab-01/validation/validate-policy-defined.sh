#!/usr/bin/env bash
# Confirms the ClusterPolicy exists, is Enforce, and scopes by Kind=Ingress,
# a name pattern and a namespaceSelector.
set -u

POLICY="require-reviewed-public-ingress"

# Server-side dry-run of an Ingress create. Args: name namespace [annotation-value]
# Prints kubectl output; return code is kubectl's.
probe_ingress() {
  local name="$1" ns="$2" ann="${3:-}"
  local annotations=""
  if [[ -n "$ann" ]]; then
    annotations="  annotations: {security-reviewed: \"$ann\"}"
  fi
  kubectl create --dry-run=server -o name -f - 2>&1 <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${name}
  namespace: ${ns}
${annotations}
spec:
  defaultBackend:
    service:
      name: probe-svc
      port:
        number: 80
YAML
}

# Poll until the probe is rejected by the policy (Kyverno needs a moment after apply).
wait_blocked() {
  local name="$1" ns="$2" out i
  for i in $(seq 1 30); do
    out=$(probe_ingress "$name" "$ns") && { sleep 2; continue; }
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
if ! echo "$json" | grep -q '"Ingress"'; then
  echo "FAIL: the rule does not match kinds: [Ingress]"
  exit 1
fi
if ! echo "$json" | grep -q 'public-\*'; then
  echo "FAIL: the rule does not scope by the public-* name pattern (names or name)"
  exit 1
fi
if ! echo "$json" | grep -q '"namespaceSelector"'; then
  echo "FAIL: the rule does not use namespaceSelector"
  exit 1
fi
echo "PASS: $POLICY is Enforce and matches Ingress, public-*, and a namespaceSelector"
exit 0
