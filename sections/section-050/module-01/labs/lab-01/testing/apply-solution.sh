#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
# UNTESTED - built from static checks only; not yet booted.
set -euo pipefail

# Apply a manifest from stdin, retrying while Kyverno's webhooks warm up.
apply_retry() {
  local manifest
  manifest="$(cat)"
  for _ in $(seq 1 30); do
    if printf '%s\n' "$manifest" | kubectl apply -f - >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  printf '%s\n' "$manifest" | kubectl apply -f -
}

# Wait until a ClusterPolicy reports Ready.
wait_policy_ready() {
  local p="$1" r
  for _ in $(seq 1 90); do
    r="$(kubectl get clusterpolicy "$p" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    [ "$r" = "True" ] && return 0
    r="$(kubectl get clusterpolicy "$p" -o jsonpath='{.status.ready}' 2>/dev/null || true)"
    [ "$r" = "true" ] && return 0
    sleep 2
  done
  echo "ClusterPolicy $p did not become Ready in time" >&2
  return 1
}

# Print "<result> <resource name>" for a policy in the reports of a namespace.
ns_results() {
  kubectl get policyreport -n "$1" -o json 2>/dev/null | jq -r --arg p "$2" \
    '.items[] as $r | $r.results[]? | select(.policy == $p) | [.result, ($r.scope.name // .resources[0].name // "")] | @tsv' | sort -u || true
}

# Same for cluster-scoped resources.
cl_results() {
  kubectl get clusterpolicyreport -o json 2>/dev/null | jq -r --arg p "$1" \
    '.items[] as $r | $r.results[]? | select(.policy == $p) | [.result, ($r.scope.name // .resources[0].name // "")] | @tsv' | sort -u || true
}

# Wait (soft) until a namespaced policy has at least N results in a namespace.
wait_ns_results() {
  local ns="$1" p="$2" want="$3" end=$((SECONDS + ${4:-300}))
  while [ "$SECONDS" -lt "$end" ]; do
    [ "$(ns_results "$ns" "$p" | wc -l | tr -d ' ')" -ge "$want" ] && return 0
    sleep 5
  done
  echo "Note: fewer than $want results for $p in $ns yet; the reports may still be arriving." >&2
  return 0
}

wait_cl_results() {
  local p="$1" want="$2" end=$((SECONDS + ${3:-300}))
  while [ "$SECONDS" -lt "$end" ]; do
    [ "$(cl_results "$p" | wc -l | tr -d ' ')" -ge "$want" ] && return 0
    sleep 5
  done
  echo "Note: fewer than $want results for $p yet; the reports may still be arriving." >&2
  return 0
}

wait_ns_results fleet-reports require-owner-label 5 300
wait_cl_results require-namespace-team 2 300

r="$(ns_results fleet-reports require-owner-label)"
failing_cm="$(printf '%s\n' "$r" | awk -F'\t' '$1=="fail"{print $2}' | sort -u | paste -sd, -)"
pass_n="$(printf '%s\n' "$r" | awk -F'\t' '$1=="pass"' | wc -l | tr -d ' ')"
fail_n="$(printf '%s\n' "$r" | awk -F'\t' '$1=="fail"' | wc -l | tr -d ' ')"
failing_ns="$(cl_results require-namespace-team | awk -F'\t' '$1=="fail"{print $2}' | sort -u | paste -sd, -)"

kubectl -n fleet-reports create configmap report-findings \
  --from-literal=failing-configmaps="$failing_cm" \
  --from-literal=pass-count="$pass_n" \
  --from-literal=fail-count="$fail_n" \
  --from-literal=failing-namespaces="$failing_ns"
