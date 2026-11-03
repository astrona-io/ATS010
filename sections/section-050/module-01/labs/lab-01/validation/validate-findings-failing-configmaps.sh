#!/usr/bin/env bash
# Check: findings. failing-configmaps equals the failing set in the PolicyReport.
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

# Check: the learner read the failing ConfigMaps right.
if ! kubectl -n fleet-reports get configmap report-findings >/dev/null 2>&1; then
  echo "FAIL: ConfigMap report-findings does not exist in fleet-reports"
  exit 1
fi
want="$(ns_results fleet-reports require-owner-label | names_with fail)"
got="$(cm_value fleet-reports report-findings failing-configmaps | tr ',' '\n' | sed 's/[[:space:]]//g' | sed '/^$/d' | sort -u | paste -sd, -)"
if [ -z "$want" ]; then
  echo "FAIL: the report currently shows no failing ConfigMaps; wait for the reports and run the check again"
  exit 1
fi
if [ "$got" != "$want" ]; then
  echo "FAIL: failing-configmaps is '${got}', the report says '${want}'"
  exit 1
fi
echo "PASS: failing-configmaps matches the report (${want})"
exit 0
