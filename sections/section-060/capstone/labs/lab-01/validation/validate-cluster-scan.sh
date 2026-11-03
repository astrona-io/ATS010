#!/usr/bin/env bash
# Check: `kyverno apply --cluster` reports the existing Pod legacy-external.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/capstone"
P="${M}/policies/restrict-registry.yaml"

[ -f "$P" ] || { echo "FAIL: $P does not exist"; exit 1; }
out="$(kyverno apply "$P" --cluster 2>&1)"
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "FAIL: kyverno apply --cluster exited 0, but legacy-external uses another registry"
  exit 1
fi
if printf '%s\n' "$out" | grep -qi 'legacy-external'; then
  echo "PASS: the cluster scan reports legacy-external"
  exit 0
fi
echo "FAIL: the --cluster output does not name legacy-external. Does the policy match Pods in namespace lab?"
exit 1
