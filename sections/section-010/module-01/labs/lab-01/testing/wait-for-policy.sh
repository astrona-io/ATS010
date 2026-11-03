#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# policy rejects a Pod without limits.
set -uo pipefail

for _ in $(seq 1 60); do
  if ! kubectl run wait-probe --image=nginx:alpine -n platform-ns --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Kyverno enforces the policy."
    exit 0
  fi
  sleep 3
done
echo "[testing] Kyverno did not enforce the policy in time." >&2
exit 1
