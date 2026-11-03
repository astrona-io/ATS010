#!/usr/bin/env bash
# Check: tests/kyverno-test.yaml has a pass and a fail result for check-registry
# and `kyverno test` succeeds.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/capstone"
T="${M}/tests/kyverno-test.yaml"
fail=0

[ -f "$T" ] || { echo "FAIL: $T does not exist"; exit 1; }
grep -Eq 'kind:[[:space:]]*Test' "$T" || { echo "FAIL: not of kind Test"; fail=1; }
grep -q 'check-registry' "$T" || { echo "FAIL: no result for rule check-registry"; fail=1; }
grep -Eq 'result:[[:space:]]*pass' "$T" || { echo "FAIL: no result expects pass"; fail=1; }
grep -Eq 'result:[[:space:]]*fail' "$T" || { echo "FAIL: no result expects fail"; fail=1; }

if kyverno test "${M}/tests" >/dev/null 2>&1; then
  echo "PASS: kyverno test tests succeeds"
else
  echo "FAIL: kyverno test tests fails; run it with --detailed-results"; fail=1
fi
exit "$fail"
