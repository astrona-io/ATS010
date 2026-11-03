#!/usr/bin/env bash
# Check: environment. Seeded reports exist (polled up to 240s each).
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

# Check: environment. All reports are in place: 3 pass + 2 fail for the ConfigMap
# policy, 1 pass + 1 fail for the Namespace policy.
ok() {
  local r; r="$(ns_results fleet-reports require-owner-label)"
  [ "$(printf '%s\n' "$r" | count_with pass)" = 3 ] && [ "$(printf '%s\n' "$r" | count_with fail)" = 2 ]
}
okc() {
  local r; r="$(cl_results require-namespace-team)"
  [ "$(printf '%s\n' "$r" | count_with pass)" = 1 ] && [ "$(printf '%s\n' "$r" | count_with fail)" = 1 ]
}
if ! poll 240 ok; then
  echo "FAIL: require-owner-label in fleet-reports does not show 3 pass and 2 fail"
  ns_results fleet-reports require-owner-label
  exit 1
fi
if ! poll 240 okc; then
  echo "FAIL: require-namespace-team does not show 1 pass and 1 fail in the ClusterPolicyReport"
  cl_results require-namespace-team
  exit 1
fi
echo "PASS: PolicyReport shows 3 pass / 2 fail and ClusterPolicyReport shows 1 pass / 1 fail"
exit 0
