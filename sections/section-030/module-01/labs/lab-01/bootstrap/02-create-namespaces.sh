#!/usr/bin/env bash
set -eu

kubectl create namespace critical-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace lenient-ns --dry-run=client -o yaml | kubectl apply -f -

echo "critical-ns and lenient-ns ready."
