#!/usr/bin/env bash
# Check: tests/limits/kyverno-test.yaml tests require-limits with one pass and
# one fail result, and `kyverno test` succeeds.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m2"
T="${M}/tests/limits/kyverno-test.yaml"
fail=0

[ -f "$T" ] || { echo "FAIL: $T does not exist"; exit 1; }

grep -Eq 'kind:[[:space:]]*Test' "$T" || { echo "FAIL: the test file is not of kind Test"; fail=1; }
grep -q 'check-limits' "$T" || { echo "FAIL: no result names the rule check-limits"; fail=1; }
grep -Eq 'result:[[:space:]]*pass' "$T" || { echo "FAIL: no result expects pass"; fail=1; }
grep -Eq 'result:[[:space:]]*fail' "$T" || { echo "FAIL: no result expects fail"; fail=1; }
grep -q 'web-ok' "$T" || { echo "FAIL: web-ok is not in the results"; fail=1; }
grep -q 'web-nolimits' "$T" || { echo "FAIL: web-nolimits is not in the results"; fail=1; }

if kyverno test "${M}/tests/limits" >/dev/null 2>&1; then
  echo "PASS: kyverno test tests/limits succeeds"
else
  echo "FAIL: kyverno test tests/limits fails; run it with --detailed-results to see which result differs"; fail=1
fi
exit "$fail"
