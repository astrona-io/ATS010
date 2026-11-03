#!/usr/bin/env bash
# Check: behaviour of the Enforce policy via server-side dry run.
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

# Check: behaviour. A server-side dry run: a violator is rejected, a compliant
# ConfigMap is admitted (polled up to 120s while the webhook settles).
bad() {
  out="$(kubectl create --dry-run=server -f - 2>&1 <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-bad
  namespace: rollout-lab
  labels:
    app: fleet
data:
  k: v
YAML
)"
  rc=$?
  [ $rc -ne 0 ] && printf '%s' "$out" | grep -qi 'require-owner-label\|owner label'
}
good() {
  kubectl create --dry-run=server -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-good
  namespace: rollout-lab
  labels:
    app: fleet
    owner: ops
data:
  k: v
YAML
}
if ! poll 120 bad; then
  echo "FAIL: a ConfigMap with app=fleet and no owner label was not rejected by require-owner-label"
  exit 1
fi
if ! poll 60 good; then
  echo "FAIL: a compliant ConfigMap (app=fleet, owner=ops) was rejected"
  exit 1
fi
echo "PASS: the violator is rejected and the compliant ConfigMap is admitted"
exit 0
