# Solution Walkthrough

Follow these steps to author, apply, and prove out the policy. Each step ends with a checkpoint so you can run `astrona submit` as you go.

---

## Step 1: Write the ClusterPolicy

Create `restrict-frontend-images.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-frontend-images
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: check-frontend-image-registry
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - apps-ns
            selector:
              matchLabels:
                tier: frontend
            operations:
              - CREATE
      exclude:
        any:
        - subjects:
            - kind: ServiceAccount
              name: ci-deployer
              namespace: apps-ns
      validate:
        message: "Frontend Pod containers must use an image from registry.internal/*."
        pattern:
          spec:
            containers:
              - image: "registry.internal/*"
```
`selector` scopes the rule to Pods that are themselves labeled `tier: frontend`; `operations: [CREATE]` means only brand-new Pods are checked; `background: false` is required because `subjects` only exists on admission requests, not on background scans of stored objects. `exclude.subjects` lets the `ci-deployer` ServiceAccount's own Pod creations skip the rule entirely.

---

## Step 2: Apply the Policy
Checkpoint: `astrona submit`; `policy-defined` should pass.

```sh
kubectl apply -f restrict-frontend-images.yaml
kubectl get clusterpolicy restrict-frontend-images
```

---

## Step 3: Confirm the Block (Normal Identity)
Checkpoint: `frontend-blocked` passes after this step.

```sh
kubectl run frontend-pod --image=nginx -n apps-ns --labels=tier=frontend
```
Expect the API server to reject this — `nginx` does not match `registry.internal/*`.

---

## Step 4: Confirm the Exclude (Impersonated ci-deployer)
Checkpoint: `ci-deployer-excluded` passes after this step.

```sh
kubectl --as=system:serviceaccount:apps-ns:ci-deployer run ci-pod --image=nginx -n apps-ns --labels=tier=frontend
```
Same disallowed image, same labels, same namespace — but this request's subject is excluded, so the rule never evaluates it and the Pod is admitted.

---

## Step 5: Confirm backend-pod Is Admitted (selector Excludes It)
Checkpoint: `out-of-scope-admitted` needs this step and the next.

```sh
kubectl run backend-pod --image=nginx -n apps-ns --labels=tier=backend
```
`tier: backend` does not satisfy `selector.matchLabels: {tier: frontend}`, so the rule never sees this Pod regardless of its image.

---

## Step 6: Confirm an UPDATE Is Out of Scope
Checkpoint: `astrona submit`; `out-of-scope-admitted` should now pass.
```sh
kubectl label pod backend-pod tier=frontend --overwrite -n apps-ns --dry-run=server
```
The request is a dry-run, so nothing changes. It is admitted because the rule lists `operations: [CREATE]`. Had it listed `UPDATE` too, this relabel would have been evaluated and rejected, because `backend-pod` runs `nginx`.

---

## Step 7: Verify Your Configuration
```sh
kubectl get pods -n apps-ns --show-labels
```
Confirm `frontend-pod` is absent, while `ci-pod` and `backend-pod` are both present. Once verified, run the local validation suite to pass the lab!
