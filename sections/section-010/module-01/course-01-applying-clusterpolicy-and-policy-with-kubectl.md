# Part 1 — Applying ClusterPolicy & Policy with kubectl

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — Enforce vs Audit at Apply Time](./course-02-enforce-vs-audit-at-apply-time.md).

## Applying a policy is applying a resource

Because `ClusterPolicy` and `Policy` are ordinary custom resources, getting one live uses the exact commands you already use for a Deployment or a ConfigMap:

```sh
kubectl apply -f require-team-label.yaml
```

`kubectl create -f` also works for a brand-new object, but `apply` is the better habit — it lets you re-run the same command after editing the file without first checking whether the object already exists.

## Kyverno validates the policy object itself

Before your rule ever evaluates a single Pod, the policy object has to get past Kyverno's own admission webhook for its own CRDs. If your YAML is structurally invalid — a `validate` and a `mutate` block in the same rule, a typo in a field name Kyverno's schema doesn't recognize, a rule with no action at all — the `kubectl apply` command itself fails with an error, and the policy never becomes live:

```text
Error from server: error when creating "bad-policy.yaml": admission webhook "validate-policy.kyverno.svc" denied the request: ...
```

> [!TIP]
> **Try it — apply and immediately inspect**
>
> ```sh
> kubectl apply -f require-team-label.yaml
> kubectl get clusterpolicy require-team-label
> ```
>
> Expect a table with a `READY` (or similarly named) column showing `true`. If `kubectl apply` succeeded but the policy never shows ready, `kubectl describe` (next) is where you find out why.

## Confirming a policy is live and ready

`kubectl get` gives you the fast summary across every policy on the cluster:

```sh
kubectl get clusterpolicy
kubectl get policy -A
```

`kubectl describe` gives you the detail — including any internal errors Kyverno's controllers hit while trying to reconcile the policy (for example, a rule referencing a `context` value that Kyverno cannot resolve):

```sh
kubectl describe clusterpolicy require-team-label
```

For the live schema of what fields a `ClusterPolicy` actually supports on the Kyverno version installed on your cluster — rather than trusting memory or a possibly-outdated doc page — ask the API server directly:

```sh
kubectl explain clusterpolicy.spec
kubectl explain clusterpolicy.spec.rules.validate
```

## Updating a live policy

There is no separate "update" verb. You edit the YAML and re-apply it:

```sh
kubectl apply -f require-team-label.yaml
```

Kyverno's controllers pick up the new `spec` and reconcile immediately — there is no restart, no rollout, no propagation delay to wait out the way you might with a Deployment's Pods.

## Deleting a policy removes its enforcement immediately

```sh
kubectl delete clusterpolicy require-team-label
```

The instant this command returns, the policy's rules stop being evaluated. Any admission webhook rules Kyverno auto-managed for this policy are cleaned up as part of the same deletion — there is no separate cleanup step you need to run.

> [!WARNING]
> **Common pitfall**
>
> Editing a policy YAML file on disk and forgetting to re-apply it is one of the most common sources of "why isn't my change taking effect?" confusion. The cluster only ever reflects what you last applied — not what your local file currently says. When in doubt, `kubectl get clusterpolicy <name> -o yaml` and diff it against your file.

## Reference

- `kubectl api-resources | grep -i kyverno` — confirms `ClusterPolicy`/`Policy` are registered and shows their scope.
- `kubectl explain clusterpolicy.spec` — the live schema for the API version installed on your cluster.
