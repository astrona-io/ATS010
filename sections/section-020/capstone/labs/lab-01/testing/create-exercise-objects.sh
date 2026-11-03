#!/usr/bin/env bash
# Waits until the policy rejects, then creates the Deployments the question asks for.
# Run only by `astrona test`, after solution/apply.sh.
set -u

deploy() { # name namespace channel
  cat <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $1
  namespace: $2
  labels: {channel: $3}
spec:
  replicas: 1
  selector:
    matchLabels: {app: $1}
  template:
    metadata:
      labels: {app: $1}
    spec:
      containers:
        - name: app
          image: nginx
YAML
}

# Wait for Kyverno to start enforcing (step 3 of the question).
for i in $(seq 1 30); do
  if ! deploy release-app store-prod stable | kubectl create -f - >/dev/null 2>&1; then
    echo "[testing] policy is enforcing."
    break
  fi
  # Admitted: the policy was not active yet. Remove it and retry.
  kubectl delete deployment release-app -n store-prod --ignore-not-found --now >/dev/null 2>&1
  sleep 2
done

deploy release-app store-prod stable | kubectl --as=system:serviceaccount:store-prod:release-bot create -f -
deploy release-canary store-prod beta | kubectl create -f -
deploy release-app store-dev stable | kubectl create -f -
echo "[testing] Exercise Deployments created."
