# Solution Walkthrough

Follow these steps to move a policy from `Audit` to `Enforce` and prove the behaviour change at each stage. After each step you can run `astrona submit` to see which checks already pass. The four checks look at the final state, so some of them fail until you reach their step.

---

## Step 1: Write the ClusterPolicy in Audit mode

Save this as `require-resource-limits.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-resource-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - platform-ns
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

---

## Step 2: Apply it and confirm it is ready

Apply it:

```sh
kubectl apply -f require-resource-limits.yaml
```

Then check the result:

```sh
kubectl get clusterpolicy require-resource-limits
kubectl wait --for=condition=Ready clusterpolicy/require-resource-limits --timeout=60s
```

The `READY` column shows `true`. If it does not, `kubectl describe clusterpolicy require-resource-limits` shows the reason.

---

## Step 3: Confirm Audit admits and reports

Create the Pod:

```sh
kubectl run no-limits-pod --image=nginx:alpine -n platform-ns
```

Then check the result:

```sh
kubectl get pod no-limits-pod -n platform-ns
kubectl get policyreport -n platform-ns
```

The Pod exists, because `Audit` does not block. The report lists `require-resource-limits` as a failing policy for it. Kyverno writes the report a few seconds after the admission, so repeat the second command if the list is empty. At this point `astrona submit` should pass `audit-era-pod-reported`.

---

## Step 4: Flip to Enforce

Edit `require-resource-limits.yaml` and change only this line:

```yaml
  validationFailureAction: Enforce
```

Apply it again:

```sh
kubectl apply -f require-resource-limits.yaml
```

---

## Step 5: Confirm Enforce blocks

Try to create the second Pod:

```sh
kubectl run no-limits-pod-2 --image=nginx:alpine -n platform-ns
```

The API server rejects the request with an error that names `require-resource-limits`. Check that the Pod was not stored:

```sh
kubectl get pod no-limits-pod-2 -n platform-ns
```

The answer is `NotFound`. The first Pod, `no-limits-pod`, is still there: `Enforce` only affects new requests.

---

## Step 6: Confirm a compliant Pod is admitted

```sh
kubectl run has-limits-pod --image=nginx:alpine -n platform-ns \
  --overrides='{"spec":{"containers":[{"name":"has-limits-pod","image":"nginx:alpine","resources":{"limits":{"cpu":"100m","memory":"64Mi"}}}]}}'
kubectl get pod has-limits-pod -n platform-ns
```

This Pod satisfies the pattern and is admitted normally.

---

## Step 7: Verify the final state

```sh
kubectl get clusterpolicy require-resource-limits -o jsonpath='{.spec.validationFailureAction}{"\n"}'
```

The output is `Enforce`. Run `astrona submit` and all four checks pass.
