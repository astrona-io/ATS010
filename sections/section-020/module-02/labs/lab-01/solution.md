# Solution Walkthrough

Follow these steps to author, apply, and prove out the policy:

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
  background: true
  rules:
    - name: check-frontend-image-registry
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - apps-ns
            objectSelector:
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
`objectSelector` scopes the rule to Pods that are themselves labeled `tier: frontend`; `operations: [CREATE]` means only brand-new Pods are checked; `exclude.subjects` lets the `ci-deployer` ServiceAccount's own Pod creations skip the rule entirely.

---

## Step 2: Apply the Policy
```sh
kubectl apply -f restrict-frontend-images.yaml
kubectl get clusterpolicy restrict-frontend-images
```

---

## Step 3: Confirm the Block (Normal Identity)
```sh
kubectl run frontend-pod --image=nginx -n apps-ns --labels=tier=frontend
```
Expect the API server to reject this — `nginx` does not match `registry.internal/*`.

---

## Step 4: Confirm the Exclude (Impersonated ci-deployer)
```sh
kubectl --as=system:serviceaccount:apps-ns:ci-deployer run ci-pod --image=nginx -n apps-ns --labels=tier=frontend
```
Same disallowed image, same labels, same namespace — but this request's subject is excluded, so the rule never evaluates it and the Pod is admitted.

---

## Step 5: Confirm backend-pod Is Admitted (objectSelector Excludes It)
```sh
kubectl run backend-pod --image=nginx -n apps-ns --labels=tier=backend
```
`tier: backend` does not satisfy `objectSelector.matchLabels: {tier: frontend}`, so the rule never sees this Pod regardless of its image.

---

## Step 6: Verify Your Configuration
```sh
kubectl get pods -n apps-ns --show-labels
```
Confirm `frontend-pod` is absent, while `ci-pod` and `backend-pod` are both present. Once verified, run the local validation suite to pass the lab!
