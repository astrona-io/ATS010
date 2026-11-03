#!/usr/bin/env bash
# Check: state. Seeded resources and Audit policies untouched.
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

# Check: nothing was changed. The task is to READ the reports, so the seeded
# resources and the Audit policies must still be as they were.
for cm in fleet-alpha fleet-bravo fleet-charlie legacy-delta legacy-echo; do
  if ! kubectl -n fleet-reports get configmap "$cm" >/dev/null 2>&1; then
    echo "FAIL: ConfigMap $cm is missing; the task is to read the reports, not to change the resources"
    exit 1
  fi
done
for p in require-owner-label require-namespace-team; do
  a="$(kubectl get clusterpolicy "$p" -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)"
  if [ "$a" != "Audit" ]; then
    echo "FAIL: ClusterPolicy $p has validationFailureAction '$a', expected Audit"
    exit 1
  fi
done
if kubectl -n fleet-reports get configmap legacy-delta -o jsonpath='{.metadata.labels.owner}' | grep -q .; then
  echo "FAIL: legacy-delta now has an owner label; leave the violators as they are"
  exit 1
fi
if kubectl get namespace reports-bad -o jsonpath='{.metadata.labels.team}' | grep -q .; then
  echo "FAIL: reports-bad now has a team label; leave the violators as they are"
  exit 1
fi
echo "PASS: resources and policies are unchanged"
exit 0
