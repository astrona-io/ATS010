#!/usr/bin/env bash
# A reviewed public Ingress is admitted, and the objects from the exercise exist.
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

if ! wait_blocked "public-probe-gate" "shop-prod"; then
  echo "FAIL: the policy is not rejecting unreviewed public-* Ingresses yet"
  exit 1
fi

fail=0
if ! out=$(probe_ingress "public-probe-ok" "shop-prod" "true"); then
  echo "FAIL: an Ingress with security-reviewed=true was rejected: $out"
  fail=1
fi
if kubectl get ingress public-shop -n shop-prod >/dev/null 2>&1; then
  echo "FAIL: public-shop exists in shop-prod; it should have been blocked"
  fail=1
fi
for pair in "internal-shop shop-prod" "public-shop shop-dev" "public-reviewed shop-prod"; do
  set -- $pair
  if ! kubectl get ingress "$1" -n "$2" >/dev/null 2>&1; then
    echo "FAIL: Ingress $1 is missing from $2"
    fail=1
  fi
done
ann=$(kubectl get ingress public-reviewed -n shop-prod -o jsonpath='{.metadata.annotations.security-reviewed}' 2>/dev/null)
if [[ -z "$ann" ]]; then
  echo "FAIL: public-reviewed has no security-reviewed annotation"
  fail=1
fi
if [[ $fail -eq 0 ]]; then
  echo "PASS: reviewed Ingresses are admitted and the exercise objects (internal-shop, public-shop in shop-dev, public-reviewed) exist"
  exit 0
fi
exit 1
