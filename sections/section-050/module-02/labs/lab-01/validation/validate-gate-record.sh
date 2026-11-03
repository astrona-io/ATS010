#!/usr/bin/env bash
# Check: gate-record numbers.
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

# Check: the learner recorded the gate numbers.
if ! kubectl -n rollout-lab get configmap gate-record >/dev/null 2>&1; then
  echo "FAIL: ConfigMap gate-record does not exist in rollout-lab"
  exit 1
fi
a="$(cm_value rollout-lab gate-record violators-found | tr -d '[:space:]')"
b="$(cm_value rollout-lab gate-record fail-at-flip | tr -d '[:space:]')"
if [ "$a" != "3" ]; then
  echo "FAIL: violators-found is '${a}', expected 3 (the fail results before you changed anything)"
  exit 1
fi
if [ "$b" != "0" ]; then
  echo "FAIL: fail-at-flip is '${b}', expected 0 (the fail results when you flipped to Enforce)"
  exit 1
fi
echo "PASS: gate-record has violators-found=3 and fail-at-flip=0"
exit 0
