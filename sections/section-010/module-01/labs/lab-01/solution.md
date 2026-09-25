# Solution Walkthrough

Follow these steps to roll a policy from `Audit` to `Enforce` and prove the behavior change at each stage:

---

## Step 1: Write the ClusterPolicy in Audit mode

Create `require-resource-limits.yaml`:
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

## Step 2: Apply and Confirm Readiness
```sh
kubectl apply -f require-resource-limits.yaml
kubectl get clusterpolicy require-resource-limits
```
Confirm the readiness column shows the policy as ready.

---

## Step 3: Confirm Audit Admits and Reports

```sh
kubectl run no-limits-pod --image=nginx:alpine -n platform-ns
kubectl get pod no-limits-pod -n platform-ns
kubectl get policyreport -n platform-ns
```
The Pod exists (Audit does not block), and the report lists `require-resource-limits` as a failing policy for it.

---

## Step 4: Flip to Enforce

Edit `require-resource-limits.yaml`, changing only:
```yaml
spec:
  validationFailureAction: Enforce
```
Re-apply:
```sh
kubectl apply -f require-resource-limits.yaml
```

---

## Step 5: Confirm Enforce Blocks

```sh
kubectl run no-limits-pod-2 --image=nginx:alpine -n platform-ns
```
Expect the API server to reject this with an admission error referencing `require-resource-limits`. `kubectl get pod no-limits-pod-2 -n platform-ns` should report `NotFound`.

---

## Step 6: Confirm a Compliant Pod Is Admitted

```sh
kubectl run has-limits-pod --image=nginx:alpine -n platform-ns \
  --overrides='{"spec":{"containers":[{"name":"has-limits-pod","image":"nginx:alpine","resources":{"limits":{"cpu":"100m","memory":"64Mi"}}}]}}'
kubectl get pod has-limits-pod -n platform-ns
```
This Pod satisfies the pattern and is admitted normally.

---

## Step 7: Verify Your Configuration

```sh
kubectl get clusterpolicy require-resource-limits -o yaml
```
Confirm `validationFailureAction: Enforce` is the final state. Once verified, run the local validation suite to pass the lab!
