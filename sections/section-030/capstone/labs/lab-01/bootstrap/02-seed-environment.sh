#!/usr/bin/env bash
set -eu

kubectl create namespace ops-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ops-legacy --dry-run=client -o yaml | kubectl apply -f -

kubectl create deployment legacy-svc --image=nginx:alpine -n ops-legacy --dry-run=client -o yaml | kubectl apply -f -
kubectl -n ops-legacy rollout status deployment/legacy-svc --timeout=120s

echo "ops-prod ready; ops-legacy and its legacy-svc Deployment ready (pre-existing, before any policy is applied)."
