#!/usr/bin/env bash
# Waits until the policy rejects, then creates the Pods the question asks for.
# Run only by `astrona test`, after solution/apply.sh.
set -u

NS="apps-ns"

# Wait for Kyverno to start enforcing (step 3 of the question).
for i in $(seq 1 30); do
  if ! kubectl run frontend-pod --image=nginx -n "$NS" --labels=tier=frontend >/dev/null 2>&1; then
    echo "[testing] policy is enforcing."
    break
  fi
  # Admitted: the policy was not active yet. Remove the Pod and retry.
  kubectl delete pod frontend-pod -n "$NS" --ignore-not-found --now >/dev/null 2>&1
  sleep 2
done

kubectl --as=system:serviceaccount:apps-ns:ci-deployer run ci-pod --image=nginx -n "$NS" --labels=tier=frontend
kubectl run backend-pod --image=nginx -n "$NS" --labels=tier=backend
echo "[testing] Exercise Pods created."
