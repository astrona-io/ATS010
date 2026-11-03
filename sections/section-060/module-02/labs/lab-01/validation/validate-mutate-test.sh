#!/usr/bin/env bash
# Check: tests/labels tests the mutate policy with an expected patched file,
# and `kyverno test` succeeds.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m2"
T="${M}/tests/labels/kyverno-test.yaml"
fail=0

[ -f "$T" ] || { echo "FAIL: $T does not exist"; exit 1; }

grep -q 'add-label' "$T" || { echo "FAIL: no result names the rule add-label"; fail=1; }
grep -q 'patchedResources' "$T" || { echo "FAIL: the result has no patchedResources field"; fail=1; }
[ -f "${M}/tests/labels/patched.yaml" ] || { echo "FAIL: tests/labels/patched.yaml (the expected Pod) does not exist"; fail=1; }
grep -Eq 'managed-by:[[:space:]]*"?kyverno"?' "${M}/tests/labels/patched.yaml" 2>/dev/null \
  || { echo "FAIL: patched.yaml does not contain managed-by: kyverno"; fail=1; }

if kyverno test "${M}/tests/labels" >/dev/null 2>&1; then
  echo "PASS: kyverno test tests/labels succeeds"
else
  echo "FAIL: kyverno test tests/labels fails; compare patched.yaml with the output of kyverno apply -o"; fail=1
fi
exit "$fail"
