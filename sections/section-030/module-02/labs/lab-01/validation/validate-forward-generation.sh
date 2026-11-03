#!/usr/bin/env bash
# Confirms forward generation still works: a namespace created after the policy
# (team-d) received default-deny-ingress.
set -u

if ! kubectl get namespace team-d >/dev/null 2>&1; then
  echo "FAIL: namespace team-d does not exist - create it after applying clone-default-netpol"
  exit 1
fi

for i in $(seq 1 30); do
  if kubectl get networkpolicy default-deny-ingress -n team-d >/dev/null 2>&1; then
    echo "PASS: team-d, created after the policy, received default-deny-ingress."
    exit 0
  fi
  sleep 2
done

echo "FAIL: default-deny-ingress not found in team-d"
exit 1
