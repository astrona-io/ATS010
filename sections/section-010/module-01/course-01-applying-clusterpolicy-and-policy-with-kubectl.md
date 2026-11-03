# Applying ClusterPolicy & Policy with kubectl

A policy only protects the cluster after the cluster has accepted it. This part follows a policy from a file on your machine to a live object and shows how to check it first, how Kyverno rejects a broken policy, how the two policy kinds differ in scope, and how to change or remove a policy.

## A policy is an ordinary resource

`ClusterPolicy` and `Policy` are custom resources, so you apply them with the same command you use for a Deployment or a ConfigMap. Kyverno does not need a special tool for this step.

The playground has a namespace `payments` with a Deployment `ledger`. The first policy asks every Pod in `payments` for a `team` label and starts in `Audit` mode, which only records violations.

<!-- astrona:playground:renew -->

Save this as `require-team-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - payments
      validate:
        message: "Every Pod must have a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

The `match` block says which resources the rule looks at. The `validate.pattern` block says what a passing resource looks like. The value `"?*"` means "at least one character".

Apply it:

```sh
kubectl apply -f require-team-label.yaml
```

You could use `kubectl create -f` for a brand-new object, but `apply` is the better habit. You can run the same `apply` again after you edit the file, without first checking whether the object exists.

## Check a policy before it goes live

A live policy changes how the whole cluster behaves, so it is worth testing a change before you store it. `kubectl` gives you two ways to do that.

`kubectl apply --dry-run=server` sends the request to the API server. The request passes through admission, including Kyverno's policy webhook, but the API server does not store anything. A server-side dry run therefore catches errors that only Kyverno can see. `--dry-run=client` only checks the file on your machine and never contacts Kyverno, so it cannot catch a Kyverno schema error.

`kubectl diff -f` shows what would change in the cluster compared with your file. It exits with code 0 when nothing differs, with code 1 when something differs, and with a higher code when the command itself fails. This makes it usable in a script or a pipeline.

Edit `require-team-label.yaml`, change `validationFailureAction` to `Enforce`, and then run:

```sh
kubectl apply --dry-run=server -f require-team-label.yaml
kubectl diff -f require-team-label.yaml
```

The diff shows one changed line, the `validationFailureAction` value. Nothing is stored yet. Change the file back to `Audit` before you continue.

## Kyverno validates the policy object itself

Before any rule looks at a Pod, Kyverno checks the policy object. A webhook that Kyverno registers for its own policy kinds receives every create and update request for a `ClusterPolicy` or `Policy`. If the structure is invalid, `kubectl apply` fails and the policy never becomes live.

A rule may contain only one action type: `validate`, `mutate`, `generate` or `verifyImages`. Save this broken policy as `bad-policy.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: bad-policy
spec:
  rules:
    - name: two-actions
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Pods need a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              team: unassigned
```

Apply it:

```sh
kubectl apply -f bad-policy.yaml
kubectl get clusterpolicy bad-policy
```

The first command fails with an error that says the admission webhook denied the request, and the reason follows. The second command reports that the policy was not found. Kyverno refused the object, so nothing was created.

## ClusterPolicy and Policy differ in scope

Kyverno has two policy kinds with the same rule syntax. A `ClusterPolicy` is a cluster-scoped object: it can match resources in any namespace, and it can match cluster-scoped resources such as Namespaces. A `Policy` is a namespaced object: it lives in one namespace and only ever checks resources in that namespace.

| Property | `ClusterPolicy` | `Policy` |
| --- | --- | --- |
| Lives in | The cluster (no namespace) | One namespace |
| Checks resources in | Any namespace, or only the ones you list | Its own namespace only |
| Can match cluster-scoped kinds | Yes | No |
| Report it writes to | `PolicyReport` per namespace, `ClusterPolicyReport` for cluster-scoped resources | `PolicyReport` in its namespace |
| Typical owner | The platform team | A team that owns one namespace |

Use a `Policy` when a team manages its own namespace and the rule should never reach further. Use a `ClusterPolicy` for a rule that the platform team owns.

Save this as `policy-no-latest.yaml`. It only affects the `payments` namespace because it lives there:

```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: no-latest-tag
  namespace: payments
spec:
  validationFailureAction: Audit
  rules:
    - name: check-image-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Use a pinned image tag, not latest."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

Apply it and list both kinds:

```sh
kubectl apply -f policy-no-latest.yaml
kubectl get clusterpolicy
kubectl get policy -A
```

`kubectl get policy` without `-A` only shows the current namespace, which is the usual reason a `Policy` seems to be missing.

## Updating and deleting a policy

There is no separate update command. Edit the file and apply it again. Kyverno reconciles the new `spec` as soon as the API server stores it. There is no restart and no rollout to wait for.

```sh
kubectl delete clusterpolicy require-team-label
kubectl delete policy no-latest-tag -n payments
```

When the delete command returns, the policy rules stop being evaluated. Kyverno also removes the admission webhook rules it built for the policy, so there is no cleanup step for you.

You now know how a policy gets into the cluster, how to check a change first, and why two policy kinds exist. The open question is what actually happens to a resource that breaks a live policy. The next part answers it.

## Common pitfalls

> [!WARNING]
> - Editing the YAML file and forgetting to apply it. The cluster only reflects what you last applied. Run `kubectl get clusterpolicy <name> -o yaml` and compare it with your file.
> - Using `--dry-run=client` and trusting it. Only `--dry-run=server` runs Kyverno's policy webhook.
> - Running `kubectl get policy` without `-A` and concluding that a namespaced policy does not exist.
