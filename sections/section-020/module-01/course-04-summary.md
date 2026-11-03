# Summary

## What you learned

You can now say exactly which resources a Kyverno rule looks at: by Kind (bare, `group/version/Kind`, or a subresource such as `Pod/exec`), by name pattern with `*` and `?`, by a static namespace list or a dynamic `namespaceSelector`, and by annotations. You know that fields in one `resources` block are ANDed, that `exclude` always beats `match`, and what a namespaced `Policy` can and cannot reach.

## Key facts

- `match` selects, `exclude` removes. A resource is evaluated only if it matches `match` and does not match `exclude`.
- Inside one `resources` block every field is ANDed. Entries in `any` are ORed; entries in `all` are ANDed.
- `kinds` accepts `Kind`, `version/Kind`, `group/version/Kind` and `Kind/subresource`. A bare `Pod` never sees `Pod/exec`.
- `name`/`names` compare `metadata.name` only. `*` is zero or more characters, `?` is exactly one. It is a glob, not a regex.
- A name pattern is a convention, not a security boundary.
- `namespaces` is a static list written in the policy. `namespaceSelector` reads the live labels of the Namespace object, so relabelling a namespace changes the scope without editing the policy.
- `annotations` matches annotations on the resource; the author of the resource controls them.
- A namespaced `Policy` only ever sees resources in its own namespace; a `ClusterPolicy` sees all namespaces.

<!-- astrona:playground:destroy -->
