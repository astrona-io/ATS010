# Solution Walkthrough

Follow these steps to author, apply, and prove out both policies:

---

## Step 1: Write the Strict Policy

Create `require-app-label-strict.yaml`:
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

## Step 2: Write the Lenient Policy

Create `require-app-label-lenient.yaml` — same rule shape, different namespace and `failurePolicy`:
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

---

## Step 3: Apply Both Policies
```sh
kubectl apply -f require-app-label-strict.yaml
kubectl apply -f require-app-label-lenient.yaml
kubectl get clusterpolicy require-app-label-strict require-app-label-lenient
```

---

## Step 4: Confirm Enforcement in critical-ns
```sh
kubectl run no-app-pod --image=nginx:alpine -n critical-ns
```
Expect this to be rejected by the admission webhook.

```sh
kubectl run has-app-pod --image=nginx:alpine -n critical-ns --labels="app=checkout"
kubectl get pod has-app-pod -n critical-ns
```
Expect this to be admitted normally.

---

## Step 5: Confirm Enforcement in lenient-ns

While Kyverno is healthy, `failurePolicy` makes no observable difference — both policies enforce identically:
```sh
kubectl run no-app-pod --image=nginx:alpine -n lenient-ns
```
Expect this to be rejected.

```sh
kubectl run has-app-pod --image=nginx:alpine -n lenient-ns --labels="app=checkout"
kubectl get pod has-app-pod -n lenient-ns
```
Expect this to be admitted.

---

## Step 6 (Exploratory Only — Not Graded): See the Failure Modes Diverge

```sh
kubectl -n kyverno get deployment kyverno-admission-controller -o jsonpath='{.status.replicas}{"\n"}'
kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=0
```
With Kyverno's admission controller down, try creating a Pod in `critical-ns` with no `app` label — expect it to still be rejected (`failurePolicy: Fail` fails closed even without Kyverno running). Try the equivalent in `lenient-ns` — expect it to be admitted anyway (`failurePolicy: Ignore` fails open).

Restore the deployment before finishing:
```sh
kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=<the count you noted above>
kubectl -n kyverno rollout status deployment/kyverno-admission-controller
```

---

## Step 7: Verify Your Configuration

```sh
kubectl get clusterpolicy require-app-label-strict -o yaml
kubectl get clusterpolicy require-app-label-lenient -o yaml
kubectl -n kyverno get deployment kyverno-admission-controller
```
Confirm `failurePolicy` and `webhookTimeoutSeconds` are set as specified on each policy, and the admission controller is back to a healthy ready state. Once verified, run the local validation suite to pass the lab!
