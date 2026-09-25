#!/usr/bin/env bash
set -eu

kubectl create namespace shop-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace shop-dev --dry-run=client -o yaml | kubectl apply -f -

kubectl label namespace shop-prod env=prod --overwrite
kubectl label namespace shop-dev env=dev --overwrite

echo "shop-prod (env=prod) and shop-dev (env=dev) ready."
