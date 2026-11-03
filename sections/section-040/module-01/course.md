# Applying Validate And Mutate Policies

A Kyverno policy does one of a small number of things to a request. A `validate` rule checks the object and allows or rejects it. A `mutate` rule changes the object before Kyverno stores it. These two policy types cover most of what platform teams ask of Kyverno: "every pod must carry a `team` label" is a validate rule, and "give every pod a `team` label when the author forgot it" is a mutate rule.

Keep one sentence in mind for this module: **the Kubernetes API server runs mutating webhooks before validating webhooks, so every mutate rule finishes before any validate rule sees the object.** This single fact explains why a mutate rule can make a validate rule pass, and why a stored object can differ from the YAML you applied.

The module has two parts. **Mutate Rules With patchStrategicMerge And patchesJson6902** writes default labels and a default `securityContext` with a merge patch, then sets a field with a JSON patch, and reads the result from the stored object. **Validate Rules, Deny Rules And Ordering** writes a `pattern` rule and a `deny` rule, proves the ordering with a mutate rule and a validate rule that depend on each other, and checks everything with `kubectl`.

## Learning objectives

After this module you can:

- Write a `mutate` rule with `patchStrategicMerge` that adds a default label and a default `securityContext` only when the author did not set one.
- Write a `mutate` rule with `patchesJson6902` and explain how it differs from a merge patch.
- Explain why mutate rules run before validate rules, and use that order on purpose.
- Prove a mutation by reading the stored object with `kubectl get -o`, not the YAML you applied.
- Write a `validate` rule with `pattern` and a `validate` rule with `deny` conditions, and choose between them.
- Switch a validate policy between `Enforce` and `Audit` and say what changes.

## Before you start

You need Kubernetes basics (namespaces, pods, labels, `kubectl apply`) and the idea of a `ClusterPolicy` with a `match` block. A **ClusterPolicy** is a Kyverno resource that holds a list of rules and applies to the whole cluster. A **rule** is one check or change inside a policy, with a `match` block that selects which objects it applies to.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with Kyverno 1.13.2 already installed and its four controllers running. It contains the namespaces `starfleet` and `outpost`, and a ConfigMap named `crew-notes` in `starfleet`. No policy exists yet. You run every command as the cluster administrator, and `kubectl` already points at the cluster.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
