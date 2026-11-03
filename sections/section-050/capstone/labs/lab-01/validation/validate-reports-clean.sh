#!/usr/bin/env bash
# Check: reports clean on both report kinds.
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

# Check: both report kinds are clean (polled up to 300s). Zero fail results
# AND passes present, so an empty report does not count as clean.
clean() {
  local a b c
  a="$(ns_results fleet-a require-owner-label)"
  b="$(ns_results fleet-b require-owner-label)"
  c="$(cl_results require-namespace-team)"
  [ "$(printf '%s\n' "$a" | count_with fail)" = 0 ] && [ "$(printf '%s\n' "$a" | count_with pass)" = 2 ] &&
  [ "$(printf '%s\n' "$b" | count_with fail)" = 0 ] && [ "$(printf '%s\n' "$b" | count_with pass)" = 2 ] &&
  ! printf '%s\n' "$b" | grep -q 'b-stale' &&
  [ "$(printf '%s\n' "$c" | count_with fail)" = 0 ] && [ "$(printf '%s\n' "$c" | count_with pass)" = 2 ]
}
if ! poll 300 clean; then
  echo "FAIL: reports are not clean yet (want fleet-a 2 pass, fleet-b 2 pass without b-stale, 2 namespace passes, 0 fail):"
  ns_results fleet-a require-owner-label
  ns_results fleet-b require-owner-label
  cl_results require-namespace-team
  exit 1
fi
echo "PASS: PolicyReports and ClusterPolicyReport show no fail and the expected passes"
exit 0
