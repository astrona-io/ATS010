#!/usr/bin/env bash
# Check: kyverno test fails when the registry in the policy is changed (run on
# a temporary copy).
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/capstone"

[ -f "${M}/policies/restrict-registry.yaml" ] || { echo "FAIL: policies/restrict-registry.yaml does not exist"; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -R "${M}/." "${tmp}/"
sed -i.bak 's#ghcr\.io/acme/#registry.invalid/other/#g' "${tmp}/policies/restrict-registry.yaml"
if cmp -s "${tmp}/policies/restrict-registry.yaml" "${M}/policies/restrict-registry.yaml"; then
  echo "FAIL: the policy does not contain the pattern ghcr.io/acme/"
  exit 1
fi
if kyverno test "${tmp}/tests" >/dev/null 2>&1; then
  echo "FAIL: kyverno test still passes with a changed registry"
  exit 1
fi
echo "PASS: kyverno test fails when the policy changes"
