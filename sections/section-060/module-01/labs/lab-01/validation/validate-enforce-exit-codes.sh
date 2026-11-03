#!/usr/bin/env bash
# Check: `kyverno apply` with require-team-label passes web-good (exit 0) and
# fails web-nolabel (non-zero exit), using the learner's own policy file.
set -u
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
M="${HOME}/kyverno-lab/m1"
P="${M}/policies/require-team-label.yaml"
fail=0

if [ ! -f "$P" ]; then echo "FAIL: $P does not exist"; exit 1; fi

if kyverno apply "$P" --resource "${M}/resources/pod-good.yaml" >/dev/null 2>&1; then
  echo "PASS: web-good passes require-team-label (exit 0)"
else
  echo "FAIL: kyverno apply exited non-zero for web-good, which has a team label"; fail=1
fi

if kyverno apply "$P" --resource "${M}/resources/pod-nolabel.yaml" >/dev/null 2>&1; then
  echo "FAIL: kyverno apply exited 0 for web-nolabel, which has no team label"; fail=1
else
  echo "PASS: web-nolabel fails require-team-label (non-zero exit)"
fi

# The policy must match only Pods in the namespace `lab`.
grep -Eq 'lab' "$P" || { echo "FAIL: the match block does not mention the namespace lab"; fail=1; }
exit "$fail"
