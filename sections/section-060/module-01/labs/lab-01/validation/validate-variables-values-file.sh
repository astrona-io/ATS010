#!/usr/bin/env bash
# Check: require-env-label reads the variable allowedEnv from the learner's
# values file. web-prod passes and web-dev fails when allowedEnv is prod.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
P="${M}/policies/require-env-label.yaml"
V="${M}/values/values.yaml"
fail=0

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }
[ -f "$V" ] || { echo "FAIL: $V does not exist"; exit 1; }

grep -q '{{' "$P" || { echo "FAIL: the policy does not use a {{ }} variable"; fail=1; }
grep -q 'allowedEnv' "$P" || { echo "FAIL: the policy does not use the variable allowedEnv"; fail=1; }
grep -Eq 'kind:[[:space:]]*Values' "$V" || { echo "FAIL: values.yaml is not of kind Values"; fail=1; }

if kyverno apply "$P" --resource "${M}/resources/pod-prod.yaml" --values-file "$V" >/dev/null 2>&1; then
  echo "PASS: web-prod (env: prod) passes with allowedEnv=prod"
else
  echo "FAIL: web-prod did not pass with --values-file values.yaml"; fail=1
fi

if kyverno apply "$P" --resource "${M}/resources/pod-dev.yaml" --values-file "$V" >/dev/null 2>&1; then
  echo "FAIL: web-dev (env: dev) passed, but allowedEnv should be prod"; fail=1
else
  echo "PASS: web-dev (env: dev) fails with allowedEnv=prod"
fi
exit "$fail"
