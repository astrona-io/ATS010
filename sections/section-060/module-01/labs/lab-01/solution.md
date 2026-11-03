# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The bootstrap installs the Kyverno CLI v1.13.2; check it with `kyverno version`.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-01/labs/lab-01
cd $HOME/kyverno-lab/m1
```

## Step 1: Enforce require-team-label

The `match` block limits the rule to Pods in the namespace `lab`. The pattern `"?*"` means: at least one character.

```sh
cat > policies/require-team-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-team
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - lab
      validate:
        message: "The label 'team' is required."
        pattern:
          metadata:
            labels:
              team: "?*"
YAML
kyverno apply policies/require-team-label.yaml --resource resources/pod-good.yaml; echo "exit=$?"
kyverno apply policies/require-team-label.yaml --resource resources/pod-nolabel.yaml; echo "exit=$?"
```

The first command prints a summary with no failure and `exit=0`. The second prints a failure for `web-nolabel` and a non-zero exit code. Submit:

```sh
astrona submit --keep
```

## Step 2: Audit policy and --audit-warn

```sh
cat > policies/disallow-latest-tag.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Audit
  rules:
    - name: no-latest
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Do not use the image tag 'latest'."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
YAML
kyverno apply policies/disallow-latest-tag.yaml --resource resources/pod-latest.yaml; echo "exit=$?"
kyverno apply policies/disallow-latest-tag.yaml --resource resources/pod-latest.yaml --audit-warn; echo "exit=$?"
```

Without the flag the Audit failure counts as a failure and the exit code is non-zero. With `--audit-warn` the summary counts it as a warning and the exit code is 0.

## Step 3: A variable from a values file

The policy and the values file:

```sh
cat > policies/require-env-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-env-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-env
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "The label 'env' must be {{ allowedEnv }}."
        pattern:
          metadata:
            labels:
              env: "{{ allowedEnv }}"
YAML
cat > values/values.yaml <<'YAML'
apiVersion: cli.kyverno.io/v1alpha1
kind: Values
policies:
  - name: require-env-label
    rules:
      - name: check-env
        values:
          allowedEnv: prod
YAML
kyverno apply policies/require-env-label.yaml --resource resources/pod-prod.yaml --values-file values/values.yaml; echo "exit=$?"
kyverno apply policies/require-env-label.yaml --resource resources/pod-dev.yaml --values-file values/values.yaml; echo "exit=$?"
```

Do not apply this policy to the cluster. A variable that has no value in a live admission request would make the policy fail. If a command stops with an error about a missing variable, check that the policy name and the rule name in the values file match the policy exactly.

## Step 4: Save the mutated resource

```sh
cat > policies/add-managed-by-label.yaml <<'YAML'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-managed-by-label
spec:
  rules:
    - name: add-label
      match:
        any:
          - resources:
              kinds:
                - Pod
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              managed-by: kyverno
YAML
kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-good.yaml -o out/patched.yaml
cat out/patched.yaml
```

The file `out/patched.yaml` shows `web-good` with the extra label. The file `resources/pod-good.yaml` stays unchanged.

## Step 5: Scan the cluster

```sh
kyverno apply policies/require-team-label.yaml --cluster; echo "exit=$?"
```

With `--cluster`, the CLI reads the Pods from the cluster in your current `kubectl` context instead of from files. It reports `legacy` as a failure. The Pod exists because it was created before any policy.

## Step 6: Apply the proven policy

```sh
kubectl apply -f policies/require-team-label.yaml
kubectl get clusterpolicy require-team-label
kubectl apply --dry-run=server -f resources/pod-nolabel.yaml
kubectl apply --dry-run=server -f resources/pod-good.yaml
```

Wait until the policy shows `READY` as true. The `web-nolabel` request is rejected with the message "The label 'team' is required." and the `web-good` request is accepted. Submit one last time:

```sh
astrona submit
```
