#!/usr/bin/env bash
# Check: `kyverno apply --cluster` against the live cluster finds the existing
# Pod `legacy` in namespace lab as a violation of require-team-label.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
P="${M}/policies/require-team-label.yaml"

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }

out="$(kyverno apply "$P" --cluster 2>&1)"
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "FAIL: kyverno apply --cluster exited 0; the Pod legacy has no team label and should fail"
  exit 1
fi
if printf '%s\n' "$out" | grep -qi 'legacy'; then
  echo "PASS: kyverno apply --cluster reports the existing Pod legacy"
  exit 0
fi
echo "FAIL: the --cluster output does not mention the Pod legacy. Does the policy match Pods in namespace lab?"
exit 1
