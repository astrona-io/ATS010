# Summary

A Kubernetes request passes through the mutating admission webhooks before the validating ones. Kyverno uses both. Every `mutate` rule finishes first, then the schema check runs, then the `validate` rules judge the final object. The object in `etcd` is the mutated one, so the proof of a mutation is always `kubectl get -o`, never the file you applied.

## What you learned

A `mutate` rule changes an object with one of two patch formats. `patchStrategicMerge` is a partial copy of the object that Kyverno merges in. The `+(field)` anchor adds a field only when the author did not set it, which is how you write a default. A conditional anchor such as `(name): "*"` applies a patch to every list element that matches. `patchesJson6902` is a string with a list of operations, each with `op`, `path` and `value`. It sets or removes an exact field, but its `add` needs the parent object to exist and it overwrites an existing value.

A `validate` rule allows or blocks the object. A `pattern` describes a good object, with `?*` for any non-empty string and `!` for negation. A `deny` rule rejects the request when its conditions are true, and it can read the operation, the user and `request.oldObject`, which is what a DELETE check needs. The policy field `validationFailureAction` decides the result of a failed check: `Enforce` rejects the request, and `Audit` admits it and records a violation. Rules that read `request` must set `background: false`.

Because mutation runs first, a mutate rule can make a validate rule pass. A pod with no `owner` label is admitted in a namespace where a mutate rule adds one, and rejected in a namespace where none does. The key facts to remember are these:

- Mutate runs before validate, whatever the order of the policies.
- `+()` supplies a default; a plain key replaces the author's value.
- Put an anchor on the single field, not on the whole `securityContext`.
- Rules in one policy run in order; do not rely on order across policies.
- Start a new validate policy in `Audit`, read the result, then switch to `Enforce`.
- Test a validate rule safely with `kubectl apply --dry-run=server`.

<!-- astrona:playground:destroy -->
