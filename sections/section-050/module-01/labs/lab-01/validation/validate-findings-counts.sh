#!/usr/bin/env bash
# Check: findings. pass-count and fail-count match the reports.
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

# Check: the learner counted results right (results, not resources).
if ! kubectl -n fleet-reports get configmap report-findings >/dev/null 2>&1; then
  echo "FAIL: ConfigMap report-findings does not exist in fleet-reports"
  exit 1
fi
r="$(ns_results fleet-reports require-owner-label)"
wp="$(printf '%s\n' "$r" | count_with pass)"
wf="$(printf '%s\n' "$r" | count_with fail)"
gp="$(cm_value fleet-reports report-findings pass-count | tr -d '[:space:]')"
gf="$(cm_value fleet-reports report-findings fail-count | tr -d '[:space:]')"
if [ "$gp" != "$wp" ]; then
  echo "FAIL: pass-count is '${gp}', the reports show ${wp} pass results for require-owner-label"
  exit 1
fi
if [ "$gf" != "$wf" ]; then
  echo "FAIL: fail-count is '${gf}', the reports show ${wf} fail results for require-owner-label"
  exit 1
fi
echo "PASS: pass-count=${gp} and fail-count=${gf} match the reports"
exit 0
