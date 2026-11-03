#!/usr/bin/env bash
# Check: policies/restrict-registry.yaml is an Enforce ClusterPolicy; the CLI
# exits 0 for the Pod `api` and non-zero for the Pod `web`.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/capstone"
P="${M}/policies/restrict-registry.yaml"
fail=0

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }
grep -Eq '^kind:[[:space:]]*ClusterPolicy' "$P" || { echo "FAIL: not a ClusterPolicy"; fail=1; }
grep -Eq '^[[:space:]]+name:[[:space:]]*restrict-registry[[:space:]]*$' "$P" || { echo "FAIL: policy name is not restrict-registry"; fail=1; }
grep -Eq 'name:[[:space:]]*check-registry[[:space:]]*$' "$P" || { echo "FAIL: no rule named check-registry"; fail=1; }
grep -Eq 'validationFailureAction:[[:space:]]*Enforce' "$P" || { echo "FAIL: validationFailureAction must be Enforce"; fail=1; }

if kyverno apply "$P" --resource "${M}/resources/pod-internal.yaml" >/dev/null 2>&1; then
  echo "PASS: api (ghcr.io/acme) passes"
else
  echo "FAIL: kyverno apply exited non-zero for api"; fail=1
fi
if kyverno apply "$P" --resource "${M}/resources/pod-external.yaml" >/dev/null 2>&1; then
  echo "FAIL: kyverno apply exited 0 for web (docker.io image)"; fail=1
else
  echo "PASS: web (docker.io) fails"
fi
exit "$fail"
