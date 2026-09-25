# Solution Walkthrough

Follow these steps to author, apply, and prove out the policy:

---

## Step 1: Write the ClusterPolicy

Create `require-approved-release.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-approved-release
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-approved-by-annotation
      match:
        any:
        - resources:
            kinds:
              - Deployment
            names:
              - "release-*"
            namespaceSelector:
              matchLabels:
                env: prod
            objectSelector:
              matchLabels:
                channel: stable
            operations:
              - CREATE
              - UPDATE
      exclude:
        any:
        - subjects:
            - kind: ServiceAccount
              name: release-bot
              namespace: store-prod
      validate:
        message: "Stable-channel release-* Deployments in production require an 'approved-by' annotation."
        pattern:
          metadata:
            annotations:
              approved-by: "?*"
```
Every field inside the single `resources` block — `names`, `namespaceSelector`, `objectSelector` — is ANDed together: a Deployment must match the name pattern, live in an `env: prod` namespace, AND carry `channel: stable` to be evaluated at all. `exclude.subjects` then lets `release-bot`'s own writes skip the rule entirely.

---

## Step 2: Apply the Policy
```sh
kubectl apply -f require-approved-release.yaml
kubectl get clusterpolicy require-approved-release
```

---

## Step 3: Confirm the Block (Normal Identity, store-prod)
```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-app
  namespace: store-prod
  labels:
    channel: stable
spec:
  replicas: 1
  selector:
    matchLabels:
      app: release-app
  template:
    metadata:
      labels:
        app: release-app
        channel: stable
    spec:
      containers:
        - name: app
          image: nginx:alpine
EOF
```
Expect the API server to reject this — no `approved-by` annotation.

---

## Step 4: Confirm the Exclude (Impersonated release-bot)
```sh
kubectl --as=system:serviceaccount:store-prod:release-bot apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-app
  namespace: store-prod
  labels:
    channel: stable
spec:
  replicas: 1
  selector:
    matchLabels:
      app: release-app
  template:
    metadata:
      labels:
        app: release-app
        channel: stable
    spec:
      containers:
        - name: app
          image: nginx:alpine
EOF
```
Same missing annotation, but this request's subject is excluded, so the Deployment is admitted.

---

## Step 5: Confirm release-canary Is Admitted (objectSelector Excludes It)
```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-canary
  namespace: store-prod
  labels:
    channel: beta
spec:
  replicas: 1
  selector:
    matchLabels:
      app: release-canary
  template:
    metadata:
      labels:
        app: release-canary
        channel: beta
    spec:
      containers:
        - name: app
          image: nginx:alpine
EOF
```
`channel: beta` does not satisfy `objectSelector.matchLabels: {channel: stable}`, so the rule never sees this Deployment.

---

## Step 6: Confirm release-app in store-dev Is Admitted (namespaceSelector Excludes It)
```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-app
  namespace: store-dev
  labels:
    channel: stable
spec:
  replicas: 1
  selector:
    matchLabels:
      app: release-app
  template:
    metadata:
      labels:
        app: release-app
        channel: stable
    spec:
      containers:
        - name: app
          image: nginx:alpine
EOF
```
`store-dev` is labeled `env: dev`, so `namespaceSelector` never selects it — the same name and channel that were blocked in `store-prod` are admitted here.

---

## Step 7: Verify Your Configuration
```sh
kubectl get deployments -n store-prod --show-labels
kubectl get deployments -n store-dev --show-labels
```
Confirm `release-app` and `release-canary` exist in `store-prod`, and `release-app` exists in `store-dev`. Once verified, run the local validation suite to pass the lab!
