#!/usr/bin/env bash
# Confirms the admission controller was restored after the exploratory scale-down.
set -u

for i in $(seq 1 30); do
  ready=$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  desired=$(kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.spec.replicas}' 2>/dev/null)
  if [[ -n "$ready" && -n "$desired" && "$ready" -ge 1 && "$ready" == "$desired" ]]; then
    echo "PASS: kyverno-admission-controller is healthy (ready=$ready, desired=$desired)."
    exit 0
  fi
  sleep 2
done

echo "FAIL: kyverno-admission-controller is not healthy (ready=${ready:-0}, desired=${desired:-?}) - scale it back up and wait for the rollout"
exit 1
