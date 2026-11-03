# Overview: Applying Generate And Cleanup Policies (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno installed and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno 1.13.2 with its admission, background, reports and cleanup controllers in the `kyverno` namespace. No extra RBAC has been added for them.
- The namespace `fleet-system` with the ConfigMap `fleet-banner`.
- The namespace `scratch` with the ConfigMaps `old-report` (label `expired: "true"`) and `keep-report` (label `expired: "false"`).
- No `ClusterPolicy`, `ClusterCleanupPolicy` or `CleanupPolicy` exists yet.

## Helpers

Paste these once in each new terminal. `can_bg` and `can_cleanup` ask whether the two Kyverno controllers may do something. `show_generated` lists what Kyverno created in a namespace. `ur_status` shows the UpdateRequests, which carry the error when a generate rule fails.

```sh
can_bg() { kubectl auth can-i "$1" "$2" --as=system:serviceaccount:kyverno:kyverno-background-controller; }
can_cleanup() { kubectl auth can-i "$1" "$2" --as=system:serviceaccount:kyverno:kyverno-cleanup-controller; }
show_generated() { kubectl get resourcequota,networkpolicy,configmap,limitrange -n "$1" --show-labels; }
ur_status() { kubectl get updaterequests -n kyverno; }
```

Use them like this: `can_bg create networkpolicies`, `can_cleanup delete configmaps`, `show_generated crew-b`, `ur_status`.

## Practice tasks

- Check `can_bg create networkpolicies` and `can_cleanup delete configmaps`. Write down the answers before you add any ClusterRole, and compare them with the behaviour of your policies.
- Write a generate rule that creates a `LimitRange` in every new namespace that has a label of your choice. Create one namespace with the label in its YAML and one that gets the label later. Predict which one gets the `LimitRange`.
- Make the same rule once with `synchronize: true` and once with `false`. Delete, edit and re-create the generated object, and write down what Kyverno does each time.
- Change the content of `fleet-banner` in `fleet-system` and see whether existing clones change under each `synchronize` value.
- Write a `CleanupPolicy` in `scratch` (a namespaced one) and a `ClusterCleanupPolicy`. Check that the namespaced policy cannot delete anything in another namespace.
- Write a cleanup condition on an annotation instead of a label, and use a default with `||` so objects without the annotation are not deleted.
- Delete the generate policy and look at what happens to objects created with `synchronize: true` and `false`.
