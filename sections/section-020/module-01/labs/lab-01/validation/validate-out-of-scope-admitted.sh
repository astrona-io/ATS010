#!/usr/bin/env bash
# Out-of-scope requests must be admitted: wrong name in prod, right name in dev.
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

# The policy must be active first, otherwise "admitted" proves nothing.
if ! wait_blocked "public-probe-gate" "shop-prod"; then
  echo "FAIL: the policy is not rejecting public-* Ingresses in shop-prod yet, so scope cannot be judged"
  exit 1
fi

fail=0
if ! out=$(probe_ingress "internal-probe" "shop-prod"); then
  echo "FAIL: internal-probe in shop-prod was rejected, but its name does not match public-*: $out"
  fail=1
fi
if ! out=$(probe_ingress "public-probe-dev" "shop-dev"); then
  echo "FAIL: public-probe-dev in shop-dev was rejected, but shop-dev is labeled env=dev, not env=prod: $out"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: internal-* in shop-prod and public-* in shop-dev are both out of scope and admitted"
  exit 0
fi
exit 1
