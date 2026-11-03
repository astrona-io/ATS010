# Summary

Generate, cleanup and image verification keep acting on the cluster after a request is finished, and two of them do their work with Kyverno's own service accounts. That is why a policy that looks right can still do nothing until the controller that runs it has the right RBAC. The way to find out is to ask the API server with `kubectl auth can-i --as=system:serviceaccount:kyverno:<controller>`.

## What you learned

A `generate` rule reacts to the creation of a trigger, such as a namespace with a given label, and the Kyverno background controller creates the new resources through an `UpdateRequest`. The content comes from `data`, which is written in the policy, or from `clone`, which copies an existing object. Rules do not touch triggers that existed before the policy, and a label added after creation does not fire a rule that reacts to the `CREATE` request. The field `synchronize` decides ownership. With `true`, Kyverno restores edits, recreates deleted objects, copies source changes to clones, and deletes the generated objects when the policy is deleted. With `false`, Kyverno creates the object once and leaves it alone.

A cleanup policy is either a `ClusterCleanupPolicy` for the whole cluster or a `CleanupPolicy` for one namespace. It has a `match` block, optional `conditions` that read the resource as `target`, and a cron `schedule`. The cleanup controller deletes with its own service account, so its ClusterRole needs the verb `delete` on the kind. A ClusterRole with the label `rbac.kyverno.io/aggregate-to-cleanup-controller` adds that right, and the label `rbac.kyverno.io/aggregate-to-background-controller` does the same for the background controller. A broad match with a wrong condition deletes real data, so narrow the match first.

Image verification checks a signature on the image digest before a pod runs. A `verifyImages` rule lists `imageReferences` and `attestors`, which hold a public key or a keyless identity. It can replace a tag with the verified digest. `Audit` reports a failure and `Enforce` rejects the pod. It needs a registry that holds the signatures and a signing key, so it is a reading topic here and not a lab. The key facts to remember are these:

- Kyverno controllers create and delete with their own service accounts; check their RBAC with `can-i --as`.
- `synchronize: true` keeps the downstream object equal to the rule; `false` creates it once.
- `generateExisting` is off by default, so existing namespaces get nothing.
- Cleanup deletes only what matches `match` and whose `conditions` are true when the schedule runs.
- `verifyImages` verifies digests, needs registry access, and should start in `Audit`.

<!-- astrona:playground:destroy -->
