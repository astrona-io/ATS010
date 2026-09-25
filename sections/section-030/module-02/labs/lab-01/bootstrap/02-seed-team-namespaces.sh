#!/usr/bin/env bash
set -eu

for ns in team-a team-b team-c; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "team-a, team-b, and team-c ready (pre-existing, before any policy is applied)."
