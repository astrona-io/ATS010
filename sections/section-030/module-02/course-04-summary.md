# Summary

A policy's rules do not have to run as an unordered pile, and Kyverno's `generate` and `mutate` rules do not have to ignore what already exists. This module covered the three rule-level settings that decide both.

## What you learned

By default `applyRules` is `"All"`: every rule of the policy that matches a resource runs, one after the other. Two rules that write the same field then fight, and the later one wins. `applyRules: "One"` turns the list into a priority-ordered decision: Kyverno stops after the first rule, in list order, that actually matches the resource. The order is the priority, with the most specific rule first and a catch-all last. It only counts rules inside this one policy; other policies still run.

By default `generate` rules are forward-only: they react to admission of a new trigger resource, so namespaces that existed before the policy get nothing. `generateExisting: true` makes Kyverno run the rule against existing trigger resources when the policy is created or updated. `mutateExistingOnPolicyUpdate: true` does the same for a `mutate` rule with a `targets` block, patching the existing targets whenever the policy is created or updated. The two fields are not interchangeable, and newer releases also accept each of them next to the rule it affects. Both backfills are done by the background controller, asynchronously, with only the rights that Kyverno's ClusterRoles give it. The key facts to remember are these:

- `applyRules: "One"` is a switch/case: order is priority, and it does not affect other policies.
- `generateExisting` belongs to `generate` rules and `mutateExistingOnPolicyUpdate` to `mutate` rules with `targets`; setting one on the wrong rule type does nothing.
- A backfill needs RBAC on the background controller, and its result appears after the policy is `Ready`, so poll for it.
- `synchronize: true` keeps generated objects in line with the policy and removes them when the policy is deleted; a mutate patch is not undone by deleting the policy.
- Plan a backfill like any bulk change: narrow the match, exclude system namespaces, check the logs.

<!-- astrona:playground:destroy -->
