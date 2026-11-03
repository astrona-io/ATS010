# Summary

## What you learned

You can now scope a rule by the resource's own labels (`selector`), by admission verb (`operations`), and by who is asking (`subjects`, `roles`, `clusterRoles`). You can combine filters with `any` (OR) and `all` (AND), predict what happens when `exclude` also applies, and follow a fixed order of checks when a rule does not behave.

## Key facts

- The Kyverno field is `selector` (labels on the **resource**); `namespaceSelector` reads labels on the **Namespace**. `objectSelector` is a webhook-configuration field, not a policy field.
- A selector supports `matchLabels` and `matchExpressions` (`In`, `NotIn`, `Exists`, `DoesNotExist`); everything listed is ANDed.
- `operations` accepts `CREATE`, `UPDATE`, `DELETE`, `CONNECT`. A `[CREATE]`-only rule does not see later edits. Subresources such as `Pod/exec` need `kinds: [Pod/exec]`, usually with `CONNECT`.
- A filter (one entry in `any`/`all`) ANDs the fields it holds; `any` ORs filters; `all` ANDs filters. Resources and subjects as two separate `any` entries mean "this resource OR this user".
- `exclude` has the same structure as `match` and always wins.
- `subjects` names an identity (`ServiceAccount`, `User`, `Group`); `roles` (`<ns>:<name>`) and `clusterRoles` match whoever holds a role through current RBAC bindings.
- Identity fields exist only on admission requests, so such policies set `background: false`.
- A subject exclude is a bypass: anyone who can authenticate as, or impersonate, that identity skips the rule.
- Debug in order: policy and action, operation and kind, object fields, requester, exclude. Probe with `--dry-run=server` and `--as`.

<!-- astrona:playground:destroy -->
