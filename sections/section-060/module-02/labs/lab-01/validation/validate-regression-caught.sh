#!/usr/bin/env bash
# Check: the tests detect a policy regression. A temporary copy of the lab
# directory gets a broken require-limits policy; `kyverno test` must then fail.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m2"

[ -d "${M}/tests" ] || { echo "FAIL: ${M}/tests does not exist"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -R "${M}/." "${tmp}/"

# Break the policy: no container can ever satisfy this memory value.
sed -i.bak 's/"?\*"/"never-matches"/' "${tmp}/policies/require-limits.yaml"
if cmp -s "${tmp}/policies/require-limits.yaml" "${M}/policies/require-limits.yaml"; then
  echo "FAIL: could not break the policy in the temporary copy (is policies/require-limits.yaml still the original?)"
  exit 1
fi

if kyverno test "${tmp}/tests/limits" >/dev/null 2>&1; then
  echo "FAIL: kyverno test still passes with a broken policy; the expected results do not check anything"
  exit 1
fi
echo "PASS: kyverno test fails when the policy is broken"
