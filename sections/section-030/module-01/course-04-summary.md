# Summary

Every admission decision is a network call from the API server to Kyverno. Two policy-level settings decide what happens when that call goes wrong, and a handful of others decide where a policy runs and what it costs.

## What you learned

`webhookTimeoutSeconds` is how long the API server waits for Kyverno's answer. It defaults to 10 and accepts 1 to 30. When the wait ends, or Kyverno cannot be reached at all, `failurePolicy` takes over. With `Fail` (the default) the request is denied; with `Ignore` it is admitted as if the policy did not exist. Kyverno writes both values into the webhook entries it registers, so the API server applies them even when Kyverno is down. `Fail` suits guardrails where one bad resource is an incident; `Ignore` suits conventions where availability matters more.

`schemaValidation` is one extra apply-time check of what `mutate` and `generate` rules would produce against the resource schema. It never changes how a policy validates other resources, and newer releases treat it as deprecated. `background` makes the policy run as a scan of existing resources; a rule that depends on the caller or the operation cannot be scanned and needs `background: false`. `admission` is the matching switch for the webhook path, so `admission: false` with `background: true` gives a scan-only policy. `validationFailureAction` (`Enforce` or `Audit`, with per-namespace overrides) decides what a healthy Kyverno does with a violation, and `emitWarning` is for sending audit violations to the client as warnings. The key facts to remember are these:

- `failurePolicy` and `webhookTimeoutSeconds` only matter when Kyverno is slow or unreachable; with a healthy Kyverno two policies that differ only in these settings behave the same.
- `Fail` can turn a Kyverno outage into a cluster-wide block; `Ignore` turns it into silently disabled enforcement.
- `schemaValidation: false` removes a safety net around the policy YAML, not any strictness on other resources.
- `background: false` marks a rule as admission-only; `admission: false` marks it as scan-only.
- `validationFailureAction` affects `validate` rules only, and is a different question from `failurePolicy`.

<!-- astrona:playground:destroy -->
