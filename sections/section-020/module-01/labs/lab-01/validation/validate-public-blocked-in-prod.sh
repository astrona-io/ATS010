#!/usr/bin/env bash
# An unreviewed public-* Ingress in an env=prod namespace must be rejected by the policy.
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

if wait_blocked "public-probe-block" "shop-prod"; then
  echo "PASS: an unannotated public-* Ingress in shop-prod is rejected by $POLICY"
  exit 0
fi
echo "FAIL: an unannotated public-* Ingress in shop-prod was not rejected by $POLICY"
exit 1
