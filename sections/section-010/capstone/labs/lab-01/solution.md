# Solution Walkthrough

Follow these steps to combine Enforce, Audit, background scanning, and PolicyExceptions in one integrated task:

---

## Step 1: Write and Apply checkout-require-limits (Enforce)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: checkout-require-limits
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-limits-checkout
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - checkout-live
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
kubectl apply -f checkout-require-limits.yaml
```

---

## Step 2: Write and Apply reporting-audit-limits (Audit)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: reporting-audit-limits
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-limits-reporting
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - reporting-live
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
kubectl apply -f reporting-audit-limits.yaml
```

---

## Step 3: Prove the Two Namespaces Behave Differently

```sh
kubectl run no-limits-checkout --image=nginx:alpine -n checkout-live
```
Expect rejection.
```sh
kubectl run no-limits-reporting --image=nginx:alpine -n reporting-live
kubectl get pod no-limits-reporting -n reporting-live
```
Expect this Pod to exist — Audit admits it.

---

## Step 4: Confirm old-reporter Is Untouched but Reported

```sh
kubectl get deployment old-reporter -n reporting-live
kubectl get policyreport -n reporting-live
```
`old-reporter` is unchanged, and appears as a violation once the background scan runs.

---

## Step 5: Enable PolicyExceptions and Exempt the Migration Job

```sh
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=checkout-live"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
```

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: allow-migration-job
  namespace: checkout-live
spec:
  exceptions:
    - policyName: checkout-require-limits
      ruleNames:
        - check-limits-checkout
        - autogen-check-limits-checkout
  match:
    any:
    - resources:
        kinds:
          - Pod
          - Job
        names:
          - "migration-job*"
```
```sh
kubectl apply -f allow-migration-job.yaml
kubectl create job migration-job -n checkout-live --image=busybox -- echo done
kubectl get job migration-job -n checkout-live
```
The Job (and the Pod it spawns) is admitted despite having no resource limits set, because the exception carves it out of `checkout-require-limits`. Once verified, run the local validation suite to pass the capstone!
