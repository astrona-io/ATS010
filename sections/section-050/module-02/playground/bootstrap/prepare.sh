#!/usr/bin/env bash
# Environment prep for the Where Results Come From and How They Age playground (ats-010-playground-050-02). No task, no grading.
# UNTESTED - built from static checks only; not yet booted.
set -euo pipefail

KYVERNO_VERSION="v1.13.2"

echo "Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"

for deploy in kyverno-admission-controller kyverno-background-controller kyverno-cleanup-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deployment/${deploy}" --timeout=300s
done

# The webhooks are registered by the admission controller after it starts.
for _ in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Kyverno is ready."

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

# Resources first, so the policies find them through a background scan.
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: fleet-reports
---
apiVersion: v1
kind: Namespace
metadata:
  name: reports-ok
  labels:
    demo: reports
    team: ops
---
apiVersion: v1
kind: Namespace
metadata:
  name: reports-bad
  labels:
    demo: reports
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fleet-alpha
  namespace: fleet-reports
  labels: {app: fleet, owner: ops}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fleet-bravo
  namespace: fleet-reports
  labels: {app: fleet, owner: platform}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fleet-charlie
  namespace: fleet-reports
  labels: {app: fleet, owner: ops}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: legacy-delta
  namespace: fleet-reports
  labels: {app: fleet}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: legacy-echo
  namespace: fleet-reports
  labels: {app: fleet}
data: {purpose: demo}
YAML

# Audit policy for namespaced resources (ConfigMaps) -> PolicyReport.
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
              namespaces: [fleet-reports]
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

# Audit policy for cluster-scoped resources (Namespaces) -> ClusterPolicyReport.
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
wait_ns_results fleet-reports require-owner-label 5 300
wait_cl_results require-namespace-team 2 300

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: rollout-lab
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ok-1
  namespace: rollout-lab
  labels: {app: fleet, owner: ops}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bad-1
  namespace: rollout-lab
  labels: {app: fleet}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bad-2
  namespace: rollout-lab
  labels: {app: fleet}
data: {purpose: demo}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bad-3
  namespace: rollout-lab
  labels: {app: fleet}
data: {purpose: demo}
YAML

echo "[playground] Ready."

