# Applying Generate And Cleanup Policies

Validate and mutate rules act on a request and then finish. Two other policy types keep working after the request is over. A `generate` rule creates a new resource when something else appears, for example a `NetworkPolicy` and a `ResourceQuota` for every new namespace. A cleanup policy deletes resources on a schedule, for example ConfigMaps that someone marked as expired. A fifth type, image verification, checks that a container image carries a signature before a pod can use it.

Keep one sentence in mind for this module: **generate and cleanup rules create and delete resources with Kyverno's own service accounts, not with the permissions of the person who triggered them, so the Kyverno controllers need the right RBAC.** Most "my policy does nothing" problems in this module come from that single fact, together with the `synchronize` setting.

The module has three parts. **Generate Rules, Synchronize And Clone** writes a rule that creates a quota, a `NetworkPolicy` and a cloned ConfigMap in every new namespace, and shows what happens when someone edits or deletes the result. **Cleanup Policies And The Cleanup Controller** writes a `ClusterCleanupPolicy` with a cron schedule and conditions, and gives the cleanup controller the right to delete. **Image Verification Overview** is reading only: it explains `verifyImages`, the `Audit` and `Enforce` modes, and why this course has no lab for it.

## Learning objectives

After this module you can:

- Write a `generate` rule that creates resources from inline `data` and by `clone` when a namespace is created.
- Explain what `synchronize: true` and `synchronize: false` do when the generated resource or the source is edited or deleted.
- Check the permissions of the Kyverno background controller and add a ClusterRole when a generate rule cannot create its target.
- Write a `ClusterCleanupPolicy` and a `CleanupPolicy` with a `schedule`, a `match` block and `conditions`.
- Give the cleanup controller the right to delete a resource kind.
- Describe what `verifyImages` checks, how `Audit` and `Enforce` differ, and why it needs a registry and a signing key.

## Before you start

You need Kubernetes basics and the idea of a `ClusterPolicy` with a `match` block. A **namespace** is a named group of resources inside a cluster. A **trigger** is the resource that causes a generate rule to run, such as a new namespace. A **downstream** resource is the resource that the rule creates.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with Kyverno 1.13.2 installed. It contains the namespace `fleet-system` with a ConfigMap `fleet-banner`, and the namespace `scratch` with two ConfigMaps named `old-report` and `keep-report`. `old-report` has the label `expired: "true"`, and `keep-report` has `expired: "false"`. No policy exists yet, and no extra RBAC has been added for Kyverno. You run every command as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
