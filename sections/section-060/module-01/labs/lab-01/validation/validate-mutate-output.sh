#!/usr/bin/env bash
# Check: add-managed-by-label adds managed-by: kyverno, and the learner saved
# the mutated Pod to out/patched.yaml with `kyverno apply -o`.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
P="${M}/policies/add-managed-by-label.yaml"
fail=0

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if kyverno apply "$P" --resource "${M}/resources/pod-good.yaml" -o "${tmp}/patched.yaml" >/dev/null 2>&1; then
  if grep -Eq 'managed-by:[[:space:]]*"?kyverno"?' "${tmp}/patched.yaml" 2>/dev/null; then
    echo "PASS: the policy adds managed-by: kyverno to the Pod"
  else
    echo "FAIL: the mutated output has no managed-by: kyverno label"; fail=1
  fi
else
  echo "FAIL: kyverno apply failed for the mutate policy"; fail=1
fi

if ! grep -Eq 'managed-by:[[:space:]]*"?kyverno"?' "${M}/out/patched.yaml" 2>/dev/null; then
  echo "FAIL: ${M}/out/patched.yaml is missing or has no managed-by: kyverno label"; fail=1
else
  echo "PASS: out/patched.yaml holds the mutated Pod"
fi

# The input file must be unchanged: the CLI never edits the source resource.
if grep -q 'managed-by' "${M}/resources/pod-good.yaml"; then
  echo "FAIL: resources/pod-good.yaml was edited; keep the input unchanged"; fail=1
fi
exit "$fail"
