# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This walkthrough has not been run against a live cluster yet; the checks describe what you should see in words.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01
```

## Step 1: Give the Kyverno controllers permission

Kyverno generates and deletes with its own service accounts. Check what they may do:

```sh
kubectl auth can-i create networkpolicies --as=system:serviceaccount:kyverno:kyverno-background-controller
kubectl auth can-i create resourcequotas --as=system:serviceaccount:kyverno:kyverno-background-controller
kubectl auth can-i delete configmaps --as=system:serviceaccount:kyverno:kyverno-cleanup-controller
```

Add two ClusterRoles with the aggregation labels, so Kyverno's own roles collect them. Save this as `kyverno-rbac.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-background-extra
  labels:
    rbac.kyverno.io/aggregate-to-background-controller: "true"
rules:
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: [""]
    resources: ["resourcequotas"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kyverno-cleanup-configmaps
  labels:
    rbac.kyverno.io/aggregate-to-cleanup-controller: "true"
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch", "delete"]
```

Apply it and run the three `can-i` commands again after a few seconds. They print `yes`.

```sh
kubectl apply -f kyverno-rbac.yaml
```

## Step 2: Generate the quota and the default-deny policy

Two rules react to a new namespace with the label `onboarding: "true"`. Both use `data` and `synchronize: true`. Save this as `onboard-namespace.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: onboard-namespace
spec:
  rules:
    - name: team-quota
      match:
        any:
          - resources:
              kinds:
                - Namespace
              selector:
                matchLabels:
                  onboarding: "true"
      generate:
        apiVersion: v1
        kind: ResourceQuota
        name: team-quota
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            hard:
              pods: "15"
    - name: default-deny-ingress
      match:
        any:
          - resources:
              kinds:
                - Namespace
              selector:
                matchLabels:
                  onboarding: "true"
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
kubectl apply -f onboard-namespace.yaml
kubectl get clusterpolicy onboard-namespace
```

Submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01 --keep
```

`controller-rbac` and `onboarding-generate` should pass. The generate check creates its own namespace, so `shipyard` (which existed before the policy) gets nothing, and that is correct.

## Step 3: Mutate and validate pods

The mutate rule adds `cost-center: shared` when the label is missing. The validate policy requires the label and rejects `hostNetwork: true`. Mutation runs first, so a pod without the label is admitted. Both policies select namespaces with a `namespaceSelector`, which is why pods in `default` are not affected.

Save this as `workload-defaults.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: workload-defaults
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  rules:
    - name: default-cost-center
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  onboarding: "true"
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(cost-center): shared
```

Save this as `workload-guardrails.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: workload-guardrails
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: require-cost-center
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  onboarding: "true"
      validate:
        message: "Every pod needs a non-empty cost-center label."
        pattern:
          metadata:
            labels:
              cost-center: "?*"
    - name: no-host-network
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  onboarding: "true"
      validate:
        message: "Pods must not use the host network."
        pattern:
          spec:
            =(hostNetwork): "false"
```

Apply both and wait until they are ready:

```sh
kubectl apply -f workload-defaults.yaml
kubectl apply -f workload-guardrails.yaml
kubectl get clusterpolicy
```

Test a pod without labels and read the stored label:

```sh
kubectl run probe --image=registry.k8s.io/pause:3.9 -n shipyard
kubectl get pod probe -n shipyard --show-labels
```

The pod is admitted and shows `cost-center=shared`. Submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01 --keep
```

`pod-mutation`, `pod-guardrails` and `policies-ready` (apart from the cleanup policy) should pass now.

## Step 4: Clean up expired ConfigMaps

The cleanup policy matches ConfigMaps in `shipyard`. The label key contains a dash, so the condition quotes it. Save this as `expire-shipyard-configmaps.yaml`:

```yaml
apiVersion: kyverno.io/v2
kind: ClusterCleanupPolicy
metadata:
  name: expire-shipyard-configmaps
spec:
  match:
    any:
      - resources:
          kinds:
            - ConfigMap
          namespaces:
            - shipyard
  conditions:
    any:
      - key: "{{ target.metadata.labels.\"ttl-expired\" || 'false' }}"
        operator: Equals
        value: "true"
  schedule: "* * * * *"
```

If `kubectl apply` says that `kyverno.io/v2` is not known, list the served versions and use one of them:

```sh
kubectl get crd clustercleanuppolicies.kyverno.io -o jsonpath='{.spec.versions[*].name}{"\n"}'
```

```sh
kubectl apply -f expire-shipyard-configmaps.yaml
kubectl get clustercleanuppolicy expire-shipyard-configmaps
```

Within about a minute `shipyard-old` disappears and `shipyard-notes` stays. Submit the final time:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01
```

All six checks should pass. Then remove the lab:

```sh
astrona destroy ats-010-lab-012
```

## If a check fails

- `onboarding-generate` fails: read `kubectl get updaterequests -n kyverno` and check the ClusterRole from step 1.
- `pod-mutation` says a pod in `default` was changed: both pod policies need a `namespaceSelector` for `onboarding: "true"` and no `namespaces` list.
- `pod-guardrails` says a label-less pod was rejected: the mutate policy is not ready or does not match `shipyard`.
- `expire-cleanup` fails with nothing deleted: check `can-i delete configmaps` for the cleanup controller and `kubectl describe clustercleanuppolicy expire-shipyard-configmaps`.
