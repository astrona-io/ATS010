#!/usr/bin/env bash
# Check: ci/run-policy-tests.sh is executable, runs `kyverno test` on the whole
# tests directory, and succeeds on the learner's tests.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m2"
S="${M}/ci/run-policy-tests.sh"
fail=0

[ -f "$S" ] || { echo "FAIL: $S does not exist"; exit 1; }
[ -x "$S" ] || { echo "FAIL: $S is not executable (chmod +x)"; fail=1; }
grep -q 'kyverno test' "$S" || { echo "FAIL: the script does not run kyverno test"; fail=1; }
grep -Eq 'set -[a-z]*e' "$S" || { echo "FAIL: the script does not stop on errors (set -e)"; fail=1; }

# It must work from any directory.
if (cd / && bash "$S" >/dev/null 2>&1); then
  echo "PASS: the CI script succeeds from another directory"
else
  echo "FAIL: the CI script fails or depends on the current directory"; fail=1
fi
exit "$fail"
