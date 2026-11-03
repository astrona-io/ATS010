#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the three
# policies are ready and the webhooks carry the new rules.
set -euo pipefail

for policy in pod-defaults require-pod-standards protect-registry; do
  for i in $(seq 1 60); do
    ready="$(kubectl get clusterpolicy "$policy" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    [ "$ready" = "True" ] && break
    sleep 2
  done
  if [ "$ready" != "True" ]; then
    echo "[testing] policy $policy was not ready in time." >&2
    exit 1
  fi
done
sleep 10
echo "[testing] policies ready."
