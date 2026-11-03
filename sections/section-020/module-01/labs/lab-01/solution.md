# Solution Walkthrough

Follow these steps to author, apply, and prove out the policy. Each step ends with an `astrona submit` loop so you can check progress as you go.

---

## Step 1: Write the ClusterPolicy

Create `require-reviewed-public-ingress.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-reviewed-public-ingress
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-security-reviewed-annotation
      match:
        any:
        - resources:
            kinds:
              - Ingress
            names:
              - "public-*"
            namespaceSelector:
              matchLabels:
                env: prod
      validate:
        message: "A non-empty 'security-reviewed' annotation is required on public Ingresses in production."
        pattern:
          metadata:
            annotations:
              security-reviewed: "?*"
```
`names: ["public-*"]` scopes the rule to Ingresses whose name starts with `public-`; `namespaceSelector` scopes it further to any namespace currently labeled `env: prod`. Both conditions live inside the same `resources` block, so they are ANDed together — an Ingress must match both the name pattern and the namespace label to be evaluated.

---

## Step 2: Apply the Policy
Checkpoint: `astrona submit` now. `policy-defined` should pass.

```sh
kubectl apply -f require-reviewed-public-ingress.yaml
kubectl get clusterpolicy require-reviewed-public-ingress
```

---

## Step 3: Confirm the Block in shop-prod
Checkpoint: after this step `public-blocked-in-prod` passes on `astrona submit`.

```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: public-shop
  namespace: shop-prod
spec:
  rules:
    - host: shop.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-frontend
                port:
                  number: 80
EOF
```
Expect the API server to reject this, referencing the `security-reviewed` annotation requirement.

---

## Step 4: Confirm internal-shop Is Admitted (Name Out of Scope)
```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-shop
  namespace: shop-prod
spec:
  rules:
    - host: internal.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: internal-svc
                port:
                  number: 80
EOF
```
`internal-shop` does not match `names: ["public-*"]`, so the rule never evaluates it — it is admitted with no annotation at all.

---

## Step 5: Confirm public-shop in shop-dev Is Admitted (Namespace Out of Scope)
Checkpoint: with steps 4 and 5 done, `out-of-scope-admitted` passes on `astrona submit`.

```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: public-shop
  namespace: shop-dev
spec:
  rules:
    - host: shop-dev.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-frontend
                port:
                  number: 80
EOF
```
`shop-dev` is labeled `env: dev`, not `env: prod`, so `namespaceSelector` never selects it — the same name pattern that was blocked in `shop-prod` is admitted here.

---

## Step 6: Confirm a Reviewed Public Ingress Is Admitted
Checkpoint: after this step `reviewed-and-objects` passes on `astrona submit`.

```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: public-reviewed
  namespace: shop-prod
  annotations:
    security-reviewed: "true"
spec:
  rules:
    - host: reviewed.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-frontend
                port:
                  number: 80
EOF
```
This satisfies the pattern and is admitted normally.

---

## Step 7: Verify Your Configuration
```sh
kubectl get ingress -n shop-prod
kubectl get ingress -n shop-dev
```
Confirm `public-shop` is absent from `shop-prod`, while `internal-shop` and `public-reviewed` are present there, and `public-shop` is present in `shop-dev`.

---

## Step 8: Prove the Scope Is Dynamic
Checkpoint: `namespace-selector-is-dynamic` creates its own probe namespace, so it can pass before or after this step. Try this step anyway to see the behaviour.

```sh
kubectl create namespace shop-stage
kubectl label namespace shop-stage env=prod
```
Now a `public-*` Ingress without the annotation is rejected in `shop-stage` too, although the policy never mentions it. That is the difference between `namespaceSelector` and a static `namespaces` list. Run `astrona submit` to check everything.

---

## Why it works
- `kinds`, `names` and `namespaceSelector` sit in the same `resources` block, so they are ANDed.
- The validate `pattern` value `"?*"` means "at least one character", so the annotation must exist and be non-empty.
- If the first rejection does not appear, Kyverno is still loading the policy. Wait a few seconds and retry.
