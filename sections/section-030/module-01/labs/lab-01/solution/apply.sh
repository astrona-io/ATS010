#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
set -euo pipefail

for spec in "strict critical-ns Fail" "lenient lenient-ns Ignore"; do
  set -- $spec
  kubectl apply -f - <<YAML
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label-$1
spec:
  validationFailureAction: Enforce
  failurePolicy: $3
  webhookTimeoutSeconds: 5
  rules:
    - name: check-app-label
      match:
        any:
        - resources:
            kinds: [Pod]
            namespaces: [$2]
      validate:
        message: "A non-empty 'app' label is required on every Pod in $2."
        pattern:
          metadata:
            labels:
              app: "?*"
YAML
  kubectl wait --for=condition=Ready "clusterpolicy/require-app-label-$1" --timeout=90s
done

for ns in critical-ns lenient-ns; do
  # The webhook can need a moment to learn the policy: retry until the unlabelled Pod is denied.
  for i in $(seq 1 30); do
    kubectl run no-app-pod --image=nginx:alpine -n "$ns" >/dev/null 2>&1 || break
    kubectl delete pod no-app-pod -n "$ns" --ignore-not-found >/dev/null 2>&1
    sleep 2
  done
  kubectl run has-app-pod --image=nginx:alpine -n "$ns" --labels=app=checkout
done
