#!/usr/bin/env bash
# Check: remediation of the three seeded violators.
# UNTESTED - built from static checks only; not yet booted.
set -u

# --- helpers (copied into every script so each check is self-contained) ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "FAIL: '$1' is required on the machine running the checks"; exit 1; }; }
need kubectl; need jq

# poll <timeout-seconds> <command...>: retry every 5s until the command succeeds.
poll() {
  local t="$1" end; shift
  end=$((SECONDS + t))
  while [ "$SECONDS" -lt "$end" ]; do
    if "$@"; then return 0; fi
    sleep 5
  done
  "$@"
}

# "<result><TAB><resource name>" for one policy; works for both report layouts.
ns_results() {
  kubectl get policyreport -n "$1" -o json 2>/dev/null | jq -r --arg p "$2" \
    '.items[] as $r | $r.results[]? | select(.policy == $p) | [.result, ($r.scope.name // .resources[0].name // "")] | @tsv' | sort -u
}
cl_results() {
  kubectl get clusterpolicyreport -o json 2>/dev/null | jq -r --arg p "$1" \
    '.items[] as $r | $r.results[]? | select(.policy == $p) | [.result, ($r.scope.name // .resources[0].name // "")] | @tsv' | sort -u
}
# names with a given result, comma-joined and sorted
names_with() { # <result> reads TSV on stdin
  awk -F'\t' -v r="$1" '$1 == r {print $2}' | sort -u | paste -sd, -
}
count_with() { awk -F'\t' -v r="$1" '$1 == r' | wc -l | tr -d ' '; }
cm_value() { kubectl -n "$1" get configmap "$2" -o "jsonpath={.data.$3}" 2>/dev/null; }

# Check: remediation. bad-1 and bad-2 were fixed with an owner label, bad-3 was
# deleted, ok-1 is still there.
for cm in ok-1 bad-1 bad-2; do
  if ! kubectl -n rollout-lab get configmap "$cm" >/dev/null 2>&1; then
    echo "FAIL: ConfigMap $cm is missing; only bad-3 should be deleted"
    exit 1
  fi
done
for cm in bad-1 bad-2; do
  o="$(kubectl -n rollout-lab get configmap "$cm" -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)"
  if [ -z "$o" ]; then
    echo "FAIL: $cm still has no owner label"
    exit 1
  fi
done
if kubectl -n rollout-lab get configmap bad-3 >/dev/null 2>&1; then
  echo "FAIL: bad-3 still exists; the task is to delete it"
  exit 1
fi
echo "PASS: bad-1 and bad-2 have an owner label, bad-3 is deleted, ok-1 remains"
exit 0
