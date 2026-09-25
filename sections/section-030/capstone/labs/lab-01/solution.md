# Solution Walkthrough

Follow these steps to author, apply, and prove out all three policies:

---

## Step 1: Write the Resource-Limits Enforcement Policy

Create `ops-require-limits.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: ops-require-limits
spec:
  validationFailureAction: Enforce
  failurePolicy: Fail
  webhookTimeoutSeconds: 8
  background: true
  rules:
    - name: check-resource-limits
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - ops-prod
      validate:
        message: "Every container in ops-prod must set CPU and memory resource limits."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    cpu: "?*"
                    memory: "?*"
```

---

## Step 2: Apply It and Confirm Enforcement

```sh
kubectl apply -f ops-require-limits.yaml
kubectl run no-limits-pod --image=nginx:alpine -n ops-prod
```
Expect this to be rejected.

```sh
kubectl run has-limits-pod --image=nginx:alpine -n ops-prod \
  --overrides='{"spec":{"containers":[{"name":"has-limits-pod","image":"nginx:alpine","resources":{"limits":{"cpu":"250m","memory":"128Mi"}}}]}}'
kubectl get pod has-limits-pod -n ops-prod
```
Expect this to be admitted.

---

## Step 3: Write the Generate Policy with generateExisting

Create `clone-audit-configmap.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-audit-configmap
spec:
  generateExisting: true
  rules:
    - name: clone-audit-config
      match:
        any:
        - resources:
            kinds:
              - Namespace
      exclude:
        any:
        - resources:
            namespaces:
              - kube-system
              - kyverno
              - kube-node-lease
              - kube-public
              - local-path-storage
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: audit-config
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          data:
            audit-level: "standard"
```

---

## Step 4: Apply It and Confirm the Backfill

```sh
kubectl apply -f clone-audit-configmap.yaml
kubectl get configmap audit-config -n ops-prod
kubectl get configmap audit-config -n ops-legacy
```
`ops-legacy` predates this policy, so seeing `audit-config` land there proves `generateExisting: true` did its job.

---

## Step 5: Write the applyRules: One Tiering Policy

Create `tier-cost-labels.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: tier-cost-labels
spec:
  applyRules: "One"
  rules:
    - name: gold-tier-override
      match:
        any:
        - resources:
            kinds:
              - Namespace
            selector:
              matchLabels:
                tier: gold
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: premium

    - name: standard-tier-default
      match:
        any:
        - resources:
            kinds:
              - Namespace
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              cost-center: standard
```

---

## Step 6: Apply It and Confirm Exactly One Outcome

```sh
kubectl apply -f tier-cost-labels.yaml
kubectl label namespace ops-prod tier=gold
kubectl get namespace ops-prod -o jsonpath='{.metadata.labels.cost-center}{"\n"}'
```
Expect `premium`. Because `applyRules: "One"` stops after the first matching rule, `standard-tier-default` never overwrites it.

---

## Step 7: Verify Your Configuration

```sh
kubectl get clusterpolicy ops-require-limits clone-audit-configmap tier-cost-labels
```
Confirm all three policies are present with the settings specified. Once verified, run the local validation suite to pass the capstone!
