# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running after a failed check.

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/capstone/labs/lab-01
cd $HOME/kyverno-lab/capstone
```

## Step 1: The policy

```sh
cat > policies/restrict-registry.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-registry
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - lab
      validate:
        message: "Images must come from ghcr.io/acme."
        pattern:
          spec:
            containers:
              - image: "ghcr.io/acme/*"
YAML
```

## Step 2: Prove it offline

```sh
kyverno apply policies/restrict-registry.yaml --resource resources/pod-internal.yaml; echo "exit=$?"
kyverno apply policies/restrict-registry.yaml --resource resources/pod-external.yaml; echo "exit=$?"
```

The first exit code is 0. The second is non-zero and the output names the `web` Pod as a failure. Submit with `astrona submit --keep`.

## Step 3: The test

```sh
cat > tests/kyverno-test.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: restrict-registry
policies:
  - ../policies/restrict-registry.yaml
resources:
  - ../resources/pod-internal.yaml
  - ../resources/pod-external.yaml
results:
  - policy: restrict-registry
    rule: check-registry
    resources:
      - api
    kind: Pod
    namespace: lab
    result: pass
  - policy: restrict-registry
    rule: check-registry
    resources:
      - web
    kind: Pod
    namespace: lab
    result: fail
YAML
kyverno test tests --detailed-results
```

## Step 4: The CI script

```sh
cat > ci/run.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."
kyverno test tests
SH
chmod +x ci/run.sh
cd / && $HOME/kyverno-lab/capstone/ci/run.sh; echo "exit=$?"; cd $HOME/kyverno-lab/capstone
```

## Step 5: Scan the cluster

```sh
kyverno apply policies/restrict-registry.yaml --cluster; echo "exit=$?"
```

The CLI reads the Pods in the cluster. `legacy-external` fails because its image comes from `registry.k8s.io`. Because the policy matches only the namespace `lab`, Pods in other namespaces do not appear.

## Step 6: Audit and --audit-warn

```sh
sed 's/validationFailureAction: Enforce/validationFailureAction: Audit/' policies/restrict-registry.yaml > /tmp/audit.yaml
kyverno apply /tmp/audit.yaml --resource resources/pod-external.yaml; echo "exit=$?"
kyverno apply /tmp/audit.yaml --resource resources/pod-external.yaml --audit-warn; echo "exit=$?"
```

The first exit code is non-zero, the second is 0. In a CI job that gates a rollout, `--audit-warn` lets a policy in Audit mode report findings without failing the job.

## Step 7: Apply to the cluster

```sh
kubectl apply -f policies/restrict-registry.yaml
kubectl get clusterpolicy restrict-registry
kubectl apply --dry-run=server -f resources/pod-external.yaml
kubectl apply --dry-run=server -f resources/pod-internal.yaml
```

Wait until the policy is Ready. The `web` request is rejected with the policy message; `api` is accepted. Submit with `astrona submit`.
