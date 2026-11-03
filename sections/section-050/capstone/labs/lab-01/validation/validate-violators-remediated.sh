#!/usr/bin/env bash
# Check: remediation of every violator.
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

# Check: remediation. Labels added, stale ConfigMap deleted, namespace labelled.
for ref in fleet-a/a-ok fleet-a/a-bad fleet-b/b-ok fleet-b/b-bad; do
  ns="${ref%%/*}"; name="${ref##*/}"
  if ! kubectl -n "$ns" get configmap "$name" >/dev/null 2>&1; then
    echo "FAIL: ConfigMap $ref is missing; only b-stale should be deleted"
    exit 1
  fi
done
for ref in fleet-a/a-bad fleet-b/b-bad; do
  ns="${ref%%/*}"; name="${ref##*/}"
  o="$(kubectl -n "$ns" get configmap "$name" -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)"
  if [ -z "$o" ]; then
    echo "FAIL: $ref still has no owner label"
    exit 1
  fi
done
if kubectl -n fleet-b get configmap b-stale >/dev/null 2>&1; then
  echo "FAIL: fleet-b/b-stale still exists; delete it"
  exit 1
fi
t="$(kubectl get namespace fleet-b -o jsonpath='{.metadata.labels.team}' 2>/dev/null)"
if [ -z "$t" ]; then
  echo "FAIL: namespace fleet-b still has no team label"
  exit 1
fi
echo "PASS: violators fixed or deleted and fleet-b has a team label"
exit 0
