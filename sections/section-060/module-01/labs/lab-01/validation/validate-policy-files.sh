#!/usr/bin/env bash
# Check: the three policy files exist with the required names, kinds and rules.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
fail=0

check_policy() { # file policy-name rule-name
  local f="${M}/policies/$1"
  if [ ! -f "$f" ]; then echo "FAIL: $f does not exist"; fail=1; return; fi
  grep -Eq '^kind:[[:space:]]*ClusterPolicy[[:space:]]*$' "$f" || { echo "FAIL: $1 is not a ClusterPolicy"; fail=1; }
  grep -Eq "^[[:space:]]+name:[[:space:]]*$2[[:space:]]*$" "$f" || { echo "FAIL: $1 has no policy named $2"; fail=1; }
  grep -Eq "^[[:space:]]*-?[[:space:]]*name:[[:space:]]*$3[[:space:]]*$" "$f" || { echo "FAIL: $1 has no rule named $3"; fail=1; }
}

check_policy require-team-label.yaml require-team-label check-team
check_policy disallow-latest-tag.yaml disallow-latest-tag no-latest
check_policy add-managed-by-label.yaml add-managed-by-label add-label
check_policy require-env-label.yaml require-env-label check-env

grep -Eq 'validationFailureAction:[[:space:]]*Enforce' "${M}/policies/require-team-label.yaml" 2>/dev/null \
  || { echo "FAIL: require-team-label must use validationFailureAction: Enforce"; fail=1; }
grep -Eq 'validationFailureAction:[[:space:]]*Audit' "${M}/policies/disallow-latest-tag.yaml" 2>/dev/null \
  || { echo "FAIL: disallow-latest-tag must use validationFailureAction: Audit"; fail=1; }

if ! command -v kyverno >/dev/null 2>&1; then
  echo "FAIL: the kyverno CLI is not on PATH"; fail=1
fi

[ "$fail" -eq 0 ] && echo "PASS: all four policy files exist with the required names"
exit "$fail"
