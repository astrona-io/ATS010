# Overview: Applying Validate And Mutate Policies (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno installed and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- Kyverno 1.13.2 with its admission, background, reports and cleanup controllers in the `kyverno` namespace.
- The namespaces `starfleet` and `outpost`, and a ConfigMap `crew-notes` in `starfleet`.
- No `ClusterPolicy` exists yet.

## Helpers

Paste these once in each new terminal. `try_pod` creates a pod and prints the labels and security context that the API server stored, or the rejection message. `drop_pod` removes it again.

```sh
try_pod() {
  kubectl run "$1" --image=registry.k8s.io/pause:3.9 -n "${2:-starfleet}" "${@:3}" \
    && kubectl get pod "$1" -n "${2:-starfleet}" -o jsonpath='{.metadata.labels}{"\n"}{.spec.containers[0].securityContext}{"\n"}'
}
drop_pod() {
  kubectl delete pod "$1" -n "${2:-starfleet}" --now --wait=false
}
policy_ready() {
  kubectl get clusterpolicy "$1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
}
```

Use them like this: `try_pod demo`, `try_pod demo2 outpost --labels=owner=ops`, `drop_pod demo`, `policy_ready require-owner-label`.

## Practice tasks

- Write a mutate rule that adds the label `environment: dev` to every pod in `starfleet` only when the pod has no `environment` label. Prove both cases with `try_pod`.
- Add `automountServiceAccountToken: false` with a merge patch and then with a JSON patch. Create a pod that sets the field to `true` and compare the two results.
- Write a validate rule with a `pattern` that requires `resources.limits.memory` on every container. Start with `Audit`, then change it to `Enforce`, and compare the pod you can create.
- Write a deny rule that blocks every `DELETE` of a ConfigMap labelled `protected=true`. Test it with `kubectl delete --dry-run=server`.
- Prove the order: create a mutate rule that adds a label and a validate rule that requires it, then apply a pod in one namespace where both match and one where only the validate rule matches.
- Run `kubectl describe clusterpolicy <name>` and `kubectl get events -n kyverno` after a failed policy and read what they say.
