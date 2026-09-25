# Solution Walkthrough

Follow these steps to author, apply, and prove out both policies:

---

## Step 1: Write the Generate Policy with generateExisting

Create `clone-default-netpol.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: clone-default-netpol
spec:
  generateExisting: true
  rules:
    - name: clone-netpol-to-namespace
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
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
```

---

## Step 2: Apply It and Confirm the Retroactive Backfill

```sh
kubectl apply -f clone-default-netpol.yaml
kubectl get networkpolicy default-deny-ingress -n team-a
kubectl get networkpolicy default-deny-ingress -n team-b
kubectl get networkpolicy default-deny-ingress -n team-c
```
Because `generateExisting: true` is set, all three pre-existing namespaces are backfilled the moment the policy is applied — you don't need to touch them yourself.

---

## Step 3: Confirm Forward-Going Generation Still Works

```sh
kubectl create namespace team-d
kubectl get networkpolicy default-deny-ingress -n team-d
```
`team-d` didn't exist when the policy was applied, so this exercises the ordinary forward-going generate path, not the retroactive backfill.

---

## Step 4: Write the applyRules: One Policy

Create `label-namespace-by-tier.yaml`:
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: label-namespace-by-tier
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

Rule order matters here: the specific gold-tier rule must come first so it gets the chance to run before the catch-all.

---

## Step 5: Apply It and Trigger the Gold-Tier Path

```sh
kubectl apply -f label-namespace-by-tier.yaml
kubectl label namespace team-a tier=gold
kubectl get namespace team-a -o jsonpath='{.metadata.labels.cost-center}{"\n"}'
```
Expect `premium`. Because `applyRules: "One"` stops after the first matching rule, `standard-tier-default` never runs against `team-a` even though it would otherwise match every `Namespace`.

---

## Step 6: Confirm the Catch-All Path

```sh
kubectl create namespace team-e
kubectl get namespace team-e -o jsonpath='{.metadata.labels.cost-center}{"\n"}'
```
Expect `standard` — `team-e` has no `tier` label, so it never matches `gold-tier-override`, and falls through to the catch-all rule.

---

## Step 7: Verify Your Configuration

```sh
kubectl get clusterpolicy clone-default-netpol -o yaml
kubectl get clusterpolicy label-namespace-by-tier -o yaml
```
Confirm `generateExisting: true` and `applyRules: "One"` are set as specified. Once verified, run the local validation suite to pass the lab!
