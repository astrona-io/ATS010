#!/usr/bin/env bash
# Check: an Audit policy failure is a failure for `kyverno apply`, and a
# warning (exit 0) when --audit-warn is set.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
P="${M}/policies/disallow-latest-tag.yaml"
fail=0

if [ ! -f "$P" ]; then echo "FAIL: $P does not exist"; exit 1; fi

if kyverno apply "$P" --resource "${M}/resources/pod-good.yaml" >/dev/null 2>&1; then
  echo "PASS: web-good (nginx:1.27) passes disallow-latest-tag"
else
  echo "FAIL: web-good was rejected by disallow-latest-tag"; fail=1
fi

if kyverno apply "$P" --resource "${M}/resources/pod-latest.yaml" >/dev/null 2>&1; then
  echo "FAIL: web-latest (nginx:latest) passed without --audit-warn"; fail=1
else
  echo "PASS: web-latest fails disallow-latest-tag by default"
fi

if kyverno apply "$P" --resource "${M}/resources/pod-latest.yaml" --audit-warn >/dev/null 2>&1; then
  echo "PASS: with --audit-warn the Audit failure is only a warning (exit 0)"
else
  echo "FAIL: with --audit-warn the command still exited non-zero; check that the policy uses validationFailureAction: Audit"; fail=1
fi
exit "$fail"
