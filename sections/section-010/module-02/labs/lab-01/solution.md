# Solution Walkthrough

Follow these steps to observe autogen and background scanning, then enable and use a PolicyException:

---

## Step 1: Write and Apply the ClusterPolicy

Create `require-resource-limits-bg.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits-bg
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-resource-limits-bg
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - background-ns
      validate:
        message: "Every container must set resources.limits.cpu and resources.limits.memory."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    cpu: "?*"
                    memory: "?*"
```
```sh
kubectl apply -f require-resource-limits-bg.yaml
```

---

## Step 2: Confirm Autogen

```sh
kubectl get clusterpolicy require-resource-limits-bg -o yaml
```
Look for the `pod-policies.kyverno.io/autogen-controllers` annotation and `autogen-`-prefixed rule entries covering `Deployment`, `ReplicaSet`, `StatefulSet`, `DaemonSet`, `Job`, and `CronJob`.

---

## Step 3: Confirm the Background Scan Flags legacy-worker

```sh
kubectl get policyreport -n background-ns
```
Wait for the background controller's scan cycle if the report isn't populated immediately. `legacy-worker`'s Pod should appear as a failing result for `require-resource-limits-bg` — and the Deployment itself remains completely unchanged:
```sh
kubectl get deployment legacy-worker -n background-ns
```

---

## Step 4: Confirm new-worker Is Blocked

```sh
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-worker
  namespace: background-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: new-worker
  template:
    metadata:
      labels:
        app: new-worker
    spec:
      containers:
        - name: new-worker
          image: nginx:alpine
EOF
```
Expect this to be rejected — autogen extended the Pod-scoped rule to cover Deployment admission directly.

---

## Step 5: Enable PolicyExceptions

```sh
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=background-ns"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
```

---

## Step 6: Create the PolicyException

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: allow-legacy-worker
  namespace: background-ns
spec:
  exceptions:
    - policyName: require-resource-limits-bg
      ruleNames:
        - check-resource-limits-bg
        - autogen-check-resource-limits-bg
  match:
    any:
    - resources:
        kinds:
          - Pod
          - Deployment
        names:
          - "legacy-worker*"
```
```sh
kubectl apply -f allow-legacy-worker.yaml
```

> The rule name list includes both the original rule and its `autogen-` counterpart, since `legacy-worker` is a Deployment and the Deployment-facing admission check runs under the autogen rule name.

---

## Step 7: Force a Re-roll and Confirm the Exception Works

```sh
kubectl -n background-ns patch deployment legacy-worker -p \
  '{"spec":{"template":{"metadata":{"annotations":{"force-reroll":"1"}}}}}'
kubectl -n background-ns rollout status deployment/legacy-worker --timeout=120s
```
The new Pod is admitted despite still having no resource limits — the exception let it through. Once verified, run the local validation suite to pass the lab!
