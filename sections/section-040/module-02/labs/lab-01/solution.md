# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This walkthrough has not been run against a live cluster yet; the checks describe what you should see in words.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01
```

## Step 1: Give the Kyverno controllers the right permissions

Kyverno creates generated resources and deletes cleaned-up resources with its own service accounts, so check their rights first:

```sh
kubectl auth can-i create networkpolicies --as=system:serviceaccount:kyverno:kyverno-background-controller
kubectl auth can-i create resourcequotas --as=system:serviceaccount:kyverno:kyverno-background-controller
kubectl auth can-i delete configmaps --as=system:serviceaccount:kyverno:kyverno-cleanup-controller
```

Each command prints `yes` or `no`. Add the two ClusterRoles in any case. The labels make Kyverno's own roles aggregate them, so you do not edit Kyverno's roles. Save this as `kyverno-rbac.yaml`:

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
    resources: ["resourcequotas", "configmaps"]
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

Apply it, wait a few seconds for the aggregation, and run the three `can-i` commands again. All three print `yes`.

```sh
kubectl apply -f kyverno-rbac.yaml
```

Submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01 --keep
```

`controller-rbac` should pass. The other checks fail because the policies do not exist yet.

## Step 2: Generate the namespace defaults

Three rules match the same trigger, a new namespace with the label `fleet-managed: "true"`. The quota and the `NetworkPolicy` use `data` and `synchronize: true`, so Kyverno restores them if someone changes them. The banner uses `clone` and `synchronize: false`, so teams may edit their copy.

Save this as `namespace-defaults.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: namespace-defaults
spec:
  rules:
    - name: default-quota
      match:
        any:
          - resources:
              kinds:
                - Namespace
              selector:
                matchLabels:
                  fleet-managed: "true"
      generate:
        apiVersion: v1
        kind: ResourceQuota
        name: default-quota
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            hard:
              pods: "10"
    - name: default-deny-ingress
      match:
        any:
          - resources:
              kinds:
                - Namespace
              selector:
                matchLabels:
                  fleet-managed: "true"
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
    - name: clone-banner
      match:
        any:
          - resources:
              kinds:
                - Namespace
              selector:
                matchLabels:
                  fleet-managed: "true"
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: fleet-banner
        namespace: "{{request.object.metadata.name}}"
        synchronize: false
        clone:
          namespace: fleet-system
          name: fleet-banner
```

Apply it and wait until it is ready:

```sh
kubectl apply -f namespace-defaults.yaml
kubectl get clusterpolicy namespace-defaults
```

Try it with a namespace that has the label in its YAML. Save this as `namespace-test.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test-gen
  labels:
    fleet-managed: "true"
```

```sh
kubectl apply -f namespace-test.yaml
kubectl get resourcequota,networkpolicy,configmap -n test-gen
```

After a few seconds the list shows `default-quota`, `default-deny-ingress` and `fleet-banner`. If it stays empty, run `kubectl get updaterequests -n kyverno` and `kubectl describe` the entry; a permission error means step 1 is incomplete. Submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01 --keep
```

`generate-on-create` and `synchronize-behaviour` should pass. `synchronize-behaviour` takes a minute or two, because it deletes and edits generated resources and waits for Kyverno to react.

## Step 3: Clean up expired ConfigMaps

A cleanup policy has its own kind. The `match` block selects ConfigMaps in `scratch`, and the condition keeps only the ones labelled `expired: "true"`. The `|| 'false'` default makes ConfigMaps without the label count as not expired.

Save this as `cleanup-expired.yaml`:

```yaml
apiVersion: kyverno.io/v2
kind: ClusterCleanupPolicy
metadata:
  name: remove-expired-configmaps
spec:
  match:
    any:
      - resources:
          kinds:
            - ConfigMap
          namespaces:
            - scratch
  conditions:
    any:
      - key: "{{ target.metadata.labels.expired || 'false' }}"
        operator: Equals
        value: "true"
  schedule: "* * * * *"
```

If `kubectl apply` says that `kyverno.io/v2` is not known, list the versions that the CRD serves and use one of them:

```sh
kubectl get crd clustercleanuppolicies.kyverno.io -o jsonpath='{.spec.versions[*].name}{"\n"}'
```

Apply the policy:

```sh
kubectl apply -f cleanup-expired.yaml
kubectl get clustercleanuppolicy remove-expired-configmaps
```

Within about a minute `old-report` disappears from `scratch`, and `keep-report` stays. Check with `kubectl get configmap -n scratch`. Submit the final time:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01
```

All five checks should pass. The cleanup check creates its own ConfigMaps and waits up to four minutes. Then remove the lab:

```sh
astrona destroy ats-010-lab-011
```

## If a check fails

- `controller-rbac` fails: the ClusterRole labels must be exactly `rbac.kyverno.io/aggregate-to-background-controller: "true"` and `rbac.kyverno.io/aggregate-to-cleanup-controller: "true"`. The aggregation can take a few seconds.
- `generate-on-create` fails: read `kubectl get updaterequests -n kyverno` and the events of the policy. Check the `namespace` expression `{{request.object.metadata.name}}` and the clone source.
- `synchronize-behaviour` says the clone edit was reverted: the clone rule must have `synchronize: false`.
- `cleanup-expired` fails with nothing deleted: check `can-i delete configmaps` for the cleanup controller, then `kubectl describe clustercleanuppolicy remove-expired-configmaps`.
