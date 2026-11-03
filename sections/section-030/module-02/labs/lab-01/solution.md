# Solution

> UNTESTED - built from static checks only; not yet booted. Expected results below are described in words, not copied from a real run.

Solve this lab on `terminal`. Each step ends with `astrona submit`. Add `--keep` if your CLI version supports it, to keep the lab running after a failed check.

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-02/labs/lab-01
```

Right after the start, all five checks should fail: there is no policy yet.

## Step 1: Write the generate policy with generateExisting

`team-a`, `team-b` and `team-c` exist already. Without `generateExisting: true` the policy would only act on namespaces created later. Create `clone-default-netpol.yaml`:

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

```sh
kubectl apply -f clone-default-netpol.yaml
kubectl wait --for=condition=Ready clusterpolicy/clone-default-netpol --timeout=90s
```

## Step 2: Check the backfill

The background controller does the work after the policy is `Ready`, so check a few times:

```sh
kubectl get networkpolicy default-deny-ingress -A
```

Expect one entry each in `team-a`, `team-b` and `team-c`, and none in `kube-system`. If nothing appears after a minute, read `kubectl -n kyverno logs deploy/kyverno-background-controller --tail=50`. Then:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-02/labs/lab-01
```

`generateexisting-backfill` should pass.

## Step 3: Prove forward generation still works

```sh
kubectl create namespace team-d
kubectl get networkpolicy default-deny-ingress -n team-d
```

Expect the NetworkPolicy to be there within a few seconds. Submit; `forward-generation` should pass.

## Step 4: Write the applyRules: One policy

Create `label-namespace-by-tier.yaml`. The gold rule must come first, because with `One` the first matching rule wins:

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

```sh
kubectl apply -f label-namespace-by-tier.yaml
kubectl wait --for=condition=Ready clusterpolicy/label-namespace-by-tier --timeout=90s
```

Submit; `applyrules-one-policy` should pass.

## Step 5: Gold tier

```sh
kubectl label namespace team-a tier=gold
kubectl get ns team-a -L tier,cost-center
```

The label change is an update of the namespace, which the mutate rules see. Expect `cost-center` to show `premium`, not `standard`. Submit; `gold-tier-premium` should pass.

## Step 6: Standard tier

```sh
kubectl create namespace team-e
kubectl get ns team-e -L tier,cost-center
```

Expect no `tier` and `cost-center` showing `standard`, from the catch-all rule. Submit; all five checks should now pass.

If `gold-tier-premium` shows `standard`, the rules are in the wrong order or `applyRules` is missing, so both rules ran and the later one overwrote the earlier.
