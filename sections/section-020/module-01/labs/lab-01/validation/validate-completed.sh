#!/usr/bin/env bash
# Confirms require-reviewed-public-ingress exists, is Enforce, blocked the
# unreviewed public Ingress in shop-prod, and left everything out of its
# scope (by name or by namespace) untouched.

set -u

policy_json=$(kubectl get clusterpolicy require-reviewed-public-ingress -o json 2>/dev/null)
if [[ -z "$policy_json" ]]; then
  echo "FAIL: require-reviewed-public-ingress - ClusterPolicy not found"
  exit 1
fi

action=$(echo "$policy_json" | grep -o '"validationFailureAction"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
if [[ "$action" != "Enforce" ]]; then
  echo "FAIL: require-reviewed-public-ingress - validationFailureAction is '$action', expected Enforce"
  exit 1
fi

if ! echo "$policy_json" | grep -q "public-\*"; then
  echo "FAIL: require-reviewed-public-ingress - policy does not scope by the 'public-*' name pattern"
  exit 1
fi

if kubectl get ingress public-shop -n shop-prod >/dev/null 2>&1; then
  echo "FAIL: public-shop exists in shop-prod - it should have been blocked by the policy"
  exit 1
fi

if ! kubectl get ingress internal-shop -n shop-prod >/dev/null 2>&1; then
  echo "FAIL: internal-shop missing from shop-prod - it should have been out of scope by name and admitted"
  exit 1
fi

if ! kubectl get ingress public-shop -n shop-dev >/dev/null 2>&1; then
  echo "FAIL: public-shop missing from shop-dev - it should have been out of scope by namespace and admitted"
  exit 1
fi

reviewed_annotation=$(kubectl get ingress public-reviewed -n shop-prod -o jsonpath='{.metadata.annotations.security-reviewed}' 2>/dev/null)
if [[ -z "$reviewed_annotation" ]]; then
  echo "FAIL: public-reviewed missing or has no 'security-reviewed' annotation in shop-prod"
  exit 1
fi

echo "PASS: require-reviewed-public-ingress enforces the annotation on public-* Ingresses in env=prod namespaces, blocked public-shop in shop-prod, and admitted internal-shop, public-shop (shop-dev), and public-reviewed (annotation=$reviewed_annotation)."
exit 0
