#!/usr/bin/env bash
set -eu

kubectl create namespace platform-ns --dry-run=client -o yaml | kubectl apply -f -

echo "platform-ns namespace ready."
