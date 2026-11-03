#!/usr/bin/env bash
# Waits until the policy rejects, then creates the objects the question asks for.
# Run only by `astrona test`, after solution/apply.sh.
set -u

ingress() { # name namespace [annotation]
  local ann=""
  [[ -n "${3:-}" ]] && ann="  annotations: {security-reviewed: \"$3\"}"
  cat <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $1
  namespace: $2
${ann}
spec:
  defaultBackend:
    service:
      name: shop-frontend
      port:
        number: 80
YAML
}

# Wait for Kyverno to start enforcing (step 3 of the question).
for i in $(seq 1 30); do
  if ! ingress public-shop shop-prod | kubectl create -f - >/dev/null 2>&1; then
    echo "[testing] policy is enforcing."
    break
  fi
  # It was admitted, so the policy was not active yet: remove it and retry.
  kubectl delete ingress public-shop -n shop-prod --ignore-not-found >/dev/null 2>&1
  sleep 2
done

ingress internal-shop shop-prod | kubectl apply -f -
ingress public-shop shop-dev | kubectl apply -f -
ingress public-reviewed shop-prod true | kubectl apply -f -
echo "[testing] Exercise objects created."
