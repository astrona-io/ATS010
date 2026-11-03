# Solution Walkthrough

Follow these steps to observe autogen and background scanning, and then enable and use a PolicyException. After each step you can run `astrona submit` to see which checks already pass. The checks look at the final state, so some of them fail until you reach their step.

---

## Step 1: Write and apply the ClusterPolicy

Save this as `require-resource-limits-bg.yaml`:

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

Apply it:

```sh
kubectl apply -f require-resource-limits-bg.yaml
```

Then check the result:

```sh
kubectl wait --for=condition=Ready clusterpolicy/require-resource-limits-bg --timeout=60s
```

---

## Step 2: Confirm autogen

```sh
kubectl get clusterpolicy require-resource-limits-bg -o yaml
kubectl get clusterpolicy require-resource-limits-bg -o jsonpath='{.status.autogen.rules[*].name}{"\n"}'
```

Look for rule names that start with `autogen-`, one for `Deployment`, `StatefulSet`, `DaemonSet` and `Job`, and one that starts with `autogen-cronjob-`. Kyverno 1.13 keeps them in `status.autogen.rules`. Older versions put them in `spec`. If the second command prints nothing, look for them in `spec.rules` in the full YAML.

---

## Step 3: Confirm the background scan reports legacy-worker

```sh
kubectl get policyreport -n background-ns
kubectl get polr -n background-ns -o json | jq -r '.items[].results[]? | select(.result=="fail") | .rule + " / " + (.resources[0].name)'
```

Run the commands again after a few seconds if the list is empty. The Pod of `legacy-worker` appears as a failing result. The Deployment itself is unchanged:

```sh
kubectl get deployment legacy-worker -n background-ns
```

---

## Step 4: Confirm new-worker is blocked

Save this as `new-worker.yaml`:

```yaml
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
```

Apply it:

```sh
kubectl apply -f new-worker.yaml
```

The API server rejects the Deployment itself, with an error that names the policy. Autogen extended the Pod rule to Deployments. If the Deployment was created, wait a little and delete it, because Kyverno had not registered the policy yet:

```sh
kubectl delete -f new-worker.yaml --ignore-not-found
```

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

Save this as `allow-legacy-worker.yaml`:

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

Apply it:

```sh
kubectl apply -f allow-legacy-worker.yaml
```

The rule list has both the original rule and its `autogen-` counterpart. `legacy-worker` is a Deployment, and the check that runs when the Deployment is updated uses the `autogen-` rule name.

---

## Step 7: Force a new Pod and confirm the exception works

```sh
kubectl -n background-ns patch deployment legacy-worker -p '{"spec":{"template":{"metadata":{"annotations":{"force-reroll":"1"}}}}}'
kubectl -n background-ns rollout status deployment/legacy-worker --timeout=120s
```

The new Pod is admitted although it still has no resource limits, because the exception lets it through. Run `astrona submit` and all five checks pass.
