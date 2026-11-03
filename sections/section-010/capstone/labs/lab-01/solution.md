# Solution Walkthrough

Follow these steps to combine `Enforce`, `Audit`, background scanning and a PolicyException in one task. After each step you can run `astrona submit` to see which checks already pass. The checks look at the final state, so some of them fail until you reach their step.

---

## Step 1: Write and apply checkout-require-limits (Enforce)

Save this as `checkout-require-limits.yaml`:

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

Apply it:

```sh
kubectl apply -f checkout-require-limits.yaml
```

---

## Step 2: Write and apply reporting-audit-limits (Audit)

Save this as `reporting-audit-limits.yaml`:

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

Apply it and check that both policies are ready:

```sh
kubectl apply -f reporting-audit-limits.yaml
kubectl get clusterpolicy
```

---

## Step 3: Prove the two namespaces behave differently

Try the Pod in `checkout-live`:

```sh
kubectl run no-limits-checkout --image=nginx:alpine -n checkout-live
```

Kyverno rejects it with an error that names `checkout-require-limits`. Now create the Pod in `reporting-live`:

```sh
kubectl run no-limits-reporting --image=nginx:alpine -n reporting-live
kubectl get pod no-limits-reporting -n reporting-live
```

The Pod exists, because `Audit` admits it. If the first command was accepted, Kyverno had not loaded the policy yet. Delete the Pod and run it again after the policy shows `READY` as `true`.

---

## Step 4: Confirm old-reporter is untouched but reported

```sh
kubectl get deployment old-reporter -n reporting-live
kubectl get policyreport -n reporting-live
```

`old-reporter` is unchanged. It appears as a failing result after the background scan has run, so repeat the second command if the list is empty.

---

## Step 5: Enable PolicyExceptions and exempt the migration Job

Patch the admission controller:

```sh
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=checkout-live"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
```

Save this as `allow-migration-job.yaml`:

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

Apply it:

```sh
kubectl apply -f allow-migration-job.yaml
```

Create the Job and check it:

```sh
kubectl create job migration-job -n checkout-live --image=busybox:1.36 -- echo done
kubectl get job migration-job -n checkout-live
kubectl get pods -n checkout-live
```

The Job and the Pod it creates are admitted although they have no limits. The exception removes them from `checkout-require-limits`, and the autogen rule name makes it work for the Job object as well as for its Pod. Run `astrona submit` and all five checks pass.
