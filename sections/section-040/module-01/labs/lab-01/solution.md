# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This walkthrough has not been run against a live cluster yet; the checks describe what you should see in words.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01
```

## Step 1: Add defaults with mutate rules

A mutate rule changes the pod before Kyverno stores it. The first rule uses a strategic merge patch. The `+()` anchor adds a field only when it is missing. The second rule uses a JSON patch with one `add` operation.

Save this as `pod-defaults.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: pod-defaults
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  rules:
    - name: default-team-and-privilege
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - starfleet
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(team): platform
          spec:
            containers:
              - (name): "*"
                securityContext:
                  +(allowPrivilegeEscalation): false
    - name: disable-token-automount
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - starfleet
      mutate:
        patchesJson6902: |-
          - op: add
            path: /spec/automountServiceAccountToken
            value: false
```

Apply it and wait until it is ready:

```sh
kubectl apply -f pod-defaults.yaml
kubectl get clusterpolicy pod-defaults
```

You should see `clusterpolicy.kyverno.io/pod-defaults created`, and `READY` becomes `True` after a few seconds. Create a pod with no labels and read the stored object:

```sh
kubectl run probe --image=registry.k8s.io/pause:3.9 -n starfleet
kubectl get pod probe -n starfleet -o jsonpath='{.metadata.labels}{"\n"}{.spec.automountServiceAccountToken}{"\n"}'
```

The label list contains `team` set to `platform`, and the second line is `false`. Submit:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01 --keep
```

`policies-ready` still fails for the two policies you have not created. `mutate-defaults` and `json6902-automount` should pass.

## Step 2: Require the label and block latest images

A validate rule judges the pod after the mutate rules finished. Because mutation runs first, the `team` label that step 1 adds satisfies the pattern.

Save this as `require-pod-standards.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-pod-standards
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: require-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - starfleet
      validate:
        message: "Every pod needs a non-empty team label."
        pattern:
          metadata:
            labels:
              team: "?*"
    - name: no-latest-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - starfleet
      validate:
        message: "Images must not use the latest tag."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

Apply it and test a pod with the `latest` tag:

```sh
kubectl apply -f require-pod-standards.yaml
kubectl get clusterpolicy require-pod-standards
kubectl run bad --image=registry.k8s.io/pause:latest -n starfleet
```

The last command is refused, and the error names `require-pod-standards` and your message. If the pod is created, the webhook has not picked up the policy yet. Delete the pod with `kubectl delete pod bad -n starfleet` and try again after a few seconds. Submit again:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01 --keep
```

`mutate-before-validate` and `reject-latest-image` should pass now.

## Step 3: Protect the registry ConfigMap

A pattern cannot see the operation, so this rule uses `deny` with a condition on `request.oldObject`. It sets `background: false` because it uses the `request` variable.

Save this as `protect-registry.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: protect-registry
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: block-delete-protected
      match:
        any:
          - resources:
              kinds:
                - ConfigMap
              namespaces:
                - starfleet
              operations:
                - DELETE
      validate:
        message: "ConfigMaps labelled protected=true cannot be deleted."
        deny:
          conditions:
            any:
              - key: "{{ request.oldObject.metadata.labels.protected || '' }}"
                operator: Equals
                value: "true"
```

Apply it and test with a server-side dry run, which sends the request through the webhooks without deleting anything:

```sh
kubectl apply -f protect-registry.yaml
kubectl delete configmap fleet-registry -n starfleet --dry-run=server
kubectl delete configmap scratch-notes -n starfleet --dry-run=server
```

The first delete is refused with your message. The second is accepted as a dry run. Submit the final time:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01
```

All six checks should pass. Then remove the lab:

```sh
astrona destroy ats-010-lab-010
```

## If a check fails

- `mutate-defaults` fails with `team=''`: the policy is not ready yet, or the label key has no `+()` anchor and your rule did not match. Run `kubectl describe clusterpolicy pod-defaults`.
- `mutate-defaults` says explicit values were overwritten: remove the plain key and use `+(team)` and `+(allowPrivilegeEscalation)`.
- `mutate-before-validate` fails with a rejected pod: the validate policy is ready but the mutate policy is not matching `starfleet`. Check `namespaces` in the `match` block.
- `deny-delete-protected` fails on `background`: Kyverno rejects a policy that reads `request` while `background` is true. Set it to `false`.
