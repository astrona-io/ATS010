#!/usr/bin/env bash
# Check: findings recorded.
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

# Check: the learner read the reports before changing anything.
if ! kubectl -n fleet-a get configmap capstone-findings >/dev/null 2>&1; then
  echo "FAIL: ConfigMap capstone-findings does not exist in fleet-a"
  exit 1
fi
norm() { tr ',' '\n' | sed 's/[[:space:]]//g' | sed '/^$/d' | sort -u | paste -sd, -; }
got="$(cm_value fleet-a capstone-findings failing-configmaps | norm)"
want="fleet-a/a-bad,fleet-b/b-bad,fleet-b/b-stale"
if [ "$got" != "$want" ]; then
  echo "FAIL: failing-configmaps is '${got}', expected the three violators as namespace/name, comma-separated: ${want}"
  exit 1
fi
gotn="$(cm_value fleet-a capstone-findings failing-namespaces | norm)"
if [ "$gotn" != "fleet-b" ]; then
  echo "FAIL: failing-namespaces is '${gotn}', expected fleet-b"
  exit 1
fi
echo "PASS: capstone-findings lists the right violators"
exit 0
