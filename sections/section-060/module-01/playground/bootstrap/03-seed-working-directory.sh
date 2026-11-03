#!/usr/bin/env bash
# Seeds the Module 1 working directory $HOME/kyverno-lab/m1 with Pod manifests,
# and creates the namespace `lab` with one non-compliant Pod named `legacy`.
set -euo pipefail

M="${HOME}/kyverno-lab/m1"
mkdir -p "${M}/resources" "${M}/policies" "${M}/values" "${M}/out"

pod() { # file name image labels...
  local file="$1" name="$2" image="$3"; shift 3
  {
    echo "apiVersion: v1"
    echo "kind: Pod"
    echo "metadata:"
    echo "  name: ${name}"
    echo "  namespace: lab"
    echo "  labels:"
    for l in "$@"; do echo "    ${l%%=*}: ${l#*=}"; done
    echo "spec:"
    echo "  containers:"
    echo "    - name: app"
    echo "      image: ${image}"
  } > "${M}/resources/${file}"
}

pod pod-good.yaml web-good nginx:1.27 app=web team=platform
pod pod-nolabel.yaml web-nolabel nginx:1.27 app=web
pod pod-latest.yaml web-latest nginx:latest app=web team=platform
pod pod-prod.yaml web-prod nginx:1.27 app=web team=platform env=prod
pod pod-dev.yaml web-dev nginx:1.27 app=web team=platform env=dev

kubectl create namespace lab --dry-run=client -o yaml | kubectl apply -f -
# A Pod that already runs in the cluster and has no `team` label. It exists
# before any policy does, so `kyverno apply --cluster` can find it.
kubectl apply -f - <<'POD'
apiVersion: v1
kind: Pod
metadata:
  name: legacy
  namespace: lab
  labels:
    app: legacy
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
POD

echo "Seeded ${M}: $(ls "${M}/resources" | wc -l | tr -d ' ') resource files."
