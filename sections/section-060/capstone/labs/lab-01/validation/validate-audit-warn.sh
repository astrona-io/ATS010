#!/usr/bin/env bash
# Check: when the policy runs in Audit mode (temporary copy), `kyverno apply`
# fails the Pod `web` by default and exits 0 with --audit-warn.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/capstone"
P="${M}/policies/restrict-registry.yaml"

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sed 's/validationFailureAction:[[:space:]]*Enforce/validationFailureAction: Audit/' "$P" > "${tmp}/audit.yaml"
grep -q 'validationFailureAction: Audit' "${tmp}/audit.yaml" || { echo "FAIL: no validationFailureAction: Enforce line to switch"; exit 1; }

fail=0
if kyverno apply "${tmp}/audit.yaml" --resource "${M}/resources/pod-external.yaml" >/dev/null 2>&1; then
  echo "FAIL: an Audit failure exited 0 without --audit-warn"; fail=1
else
  echo "PASS: an Audit failure exits non-zero by default"
fi
if kyverno apply "${tmp}/audit.yaml" --resource "${M}/resources/pod-external.yaml" --audit-warn >/dev/null 2>&1; then
  echo "PASS: --audit-warn turns the Audit failure into a warning (exit 0)"
else
  echo "FAIL: --audit-warn still exits non-zero"; fail=1
fi
exit "$fail"
