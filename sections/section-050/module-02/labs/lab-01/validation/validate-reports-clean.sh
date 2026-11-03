#!/usr/bin/env bash
# Check: reports clean (polled up to 300s).
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

# Check: the reports caught up. Zero fail results, exactly three pass results
# (ok-1, bad-1, bad-2) and nothing left for bad-3 (polled up to 300s).
clean() {
  local r f p
  r="$(ns_results rollout-lab require-owner-label)"
  f="$(printf '%s\n' "$r" | count_with fail)"
  p="$(printf '%s\n' "$r" | count_with pass)"
  [ "$f" = 0 ] && [ "$p" = 3 ] && ! printf '%s\n' "$r" | grep -q 'bad-3'
}
if ! poll 300 clean; then
  echo "FAIL: reports for require-owner-label in rollout-lab are not clean yet (want 0 fail, 3 pass, no bad-3):"
  ns_results rollout-lab require-owner-label
  exit 1
fi
echo "PASS: reports show 0 fail, 3 pass and no result for the deleted bad-3"
exit 0
