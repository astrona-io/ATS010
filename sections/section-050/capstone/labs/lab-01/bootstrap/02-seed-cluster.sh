#!/usr/bin/env bash
# Seeds fleet-a and fleet-b, two Audit policies; waits (softly) for the reports.
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

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: fleet-a
  labels: {demo: reports, team: ops}
---
apiVersion: v1
kind: Namespace
metadata:
  name: fleet-b
  labels: {demo: reports}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: a-ok
  namespace: fleet-a
  labels: {app: fleet, owner: ops}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: a-bad
  namespace: fleet-a
  labels: {app: fleet}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: b-ok
  namespace: fleet-b
  labels: {app: fleet, owner: platform}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: b-bad
  namespace: fleet-b
  labels: {app: fleet}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: b-stale
  namespace: fleet-b
  labels: {app: fleet}
data: {purpose: demo}
YAML

apply_retry <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-owner-label
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-owner-label
      match:
        any:
          - resources:
              kinds: [ConfigMap]
              namespaces: [fleet-a, fleet-b]
              selector:
                matchLabels:
                  app: fleet
      validate:
        message: "ConfigMaps labelled app=fleet must carry an owner label."
        pattern:
          metadata:
            labels:
              owner: "?*"
YAML

apply_retry <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-namespace-team
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds: [Namespace]
              selector:
                matchLabels:
                  demo: reports
      validate:
        message: "Namespaces labelled demo=reports must carry a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
YAML

wait_policy_ready require-owner-label
wait_policy_ready require-namespace-team
wait_ns_results fleet-a require-owner-label 2 300
wait_ns_results fleet-b require-owner-label 3 300
wait_cl_results require-namespace-team 2 300

