#!/usr/bin/env bash
# Check: behaviour of both Enforce policies via server-side dry run.
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

# Check: behaviour of Enforce on both policies, by server-side dry run.
rejects() { # <name> <yaml> <pattern>
  local out
  out="$(printf '%s\n' "$2" | kubectl create --dry-run=server -f - 2>&1)" && return 1
  printf '%s' "$out" | grep -qi "$3"
}
accepts() { printf '%s\n' "$1" | kubectl create --dry-run=server -f - >/dev/null 2>&1; }

bad_cm='apiVersion: v1
kind: ConfigMap
metadata: {name: probe-bad, namespace: fleet-a, labels: {app: fleet}}
data: {k: v}'
good_cm='apiVersion: v1
kind: ConfigMap
metadata: {name: probe-good, namespace: fleet-a, labels: {app: fleet, owner: ops}}
data: {k: v}'
bad_ns='apiVersion: v1
kind: Namespace
metadata: {name: fleet-c, labels: {demo: reports}}'
good_ns='apiVersion: v1
kind: Namespace
metadata: {name: fleet-c, labels: {demo: reports, team: ops}}'

poll 120 rejects x "$bad_cm" 'require-owner-label\|owner label' || { echo "FAIL: a ConfigMap without owner label was not rejected in fleet-a"; exit 1; }
poll 60 accepts "$good_cm" || { echo "FAIL: a compliant ConfigMap was rejected in fleet-a"; exit 1; }
poll 120 rejects x "$bad_ns" 'require-namespace-team\|team label' || { echo "FAIL: a Namespace with demo=reports and no team label was not rejected"; exit 1; }
poll 60 accepts "$good_ns" || { echo "FAIL: a Namespace with demo=reports and a team label was rejected"; exit 1; }
echo "PASS: violators are rejected and compliant objects are admitted for both policies"
exit 0
