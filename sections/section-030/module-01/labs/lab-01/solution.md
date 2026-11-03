# Solution

> UNTESTED - built from static checks only; not yet booted. Expected results below are described in words, not copied from a real run.

Solve this lab on `terminal`. Each step ends with `astrona submit`. Add `--keep` if your CLI version supports it, to keep the lab running after a failed check.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
```

Right after the start, `astrona submit` should show the admission-controller check passing (Kyverno is healthy) and the four policy checks failing.

## Step 1: Write the strict policy

`failurePolicy` and `webhookTimeoutSeconds` are policy-level settings, so they sit directly under `spec`, next to `validationFailureAction`. Create `require-app-label-strict.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label-strict
spec:
  validationFailureAction: Enforce
  failurePolicy: Fail
  webhookTimeoutSeconds: 5
  rules:
    - name: check-app-label
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - critical-ns
      validate:
        message: "A non-empty 'app' label is required on every Pod in critical-ns."
        pattern:
          metadata:
            labels:
              app: "?*"
```

## Step 2: Write the lenient policy

Same rule shape, different namespace and `failurePolicy`. Create `require-app-label-lenient.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label-lenient
spec:
  validationFailureAction: Enforce
  failurePolicy: Ignore
  webhookTimeoutSeconds: 5
  rules:
    - name: check-app-label
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - lenient-ns
      validate:
        message: "A non-empty 'app' label is required on every Pod in lenient-ns."
        pattern:
          metadata:
            labels:
              app: "?*"
```

## Step 3: Apply both policies and wait for Ready

```sh
kubectl apply -f require-app-label-strict.yaml
kubectl apply -f require-app-label-lenient.yaml
kubectl wait --for=condition=Ready clusterpolicy/require-app-label-strict clusterpolicy/require-app-label-lenient --timeout=90s
```

Expect both policies to report `Ready`. Now submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
```

Expect `strict-policy-settings` and `lenient-policy-settings` to pass. If one fails, the message names the field it read and the value it found.

## Step 4: Prove enforcement in critical-ns

```sh
kubectl run no-app-pod --image=nginx:alpine -n critical-ns
kubectl run has-app-pod --image=nginx:alpine -n critical-ns --labels="app=checkout"
kubectl get pod has-app-pod -n critical-ns
```

The first command should be rejected by the admission webhook with the policy's message. If it is admitted instead, the webhook does not know the policy yet: delete the Pod, wait a few seconds and try again. The second should be admitted. Submit again; `critical-ns-enforces-label` should pass.

## Step 5: Prove enforcement in lenient-ns

While Kyverno is healthy, `failurePolicy` makes no observable difference, so both policies enforce identically:

```sh
kubectl run no-app-pod --image=nginx:alpine -n lenient-ns
kubectl run has-app-pod --image=nginx:alpine -n lenient-ns --labels="app=checkout"
kubectl get pod has-app-pod -n lenient-ns
```

Expect the first to be rejected and the second admitted. Submit again; `lenient-ns-enforces-label` should pass.

## Step 6 (exploratory, not graded): see the failure modes diverge

```sh
kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=0
```

With the admission controller down, create an unlabelled Pod in `critical-ns` and expect an error about calling the webhook (fail closed). Do the same in `lenient-ns` and expect the Pod to be created (fail open); delete it afterwards with `kubectl delete pod <name> -n lenient-ns`, because it is an unlabelled Pod the policy would have refused. Restore the deployment before you finish:

```sh
kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=<the count you noted above>
kubectl -n kyverno rollout status deployment/kyverno-admission-controller
```

## Step 7: Final submit

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
```

All five checks should pass. If `admission-controller-healthy` fails, the controller is still scaled down or still rolling out.
