# Section 020 Knowledge Check: Resource Selection

Test your understanding of `resources.kinds` qualification, `name`/`names` and wildcards, static `namespaces` vs dynamic `namespaceSelector`, `objectSelector` vs `namespaceSelector`, `operations`, `match.any`/`match.all`, and identity-based selection with `subjects`.

---

## Scenario-Based Questions

### Question 1
Your cluster has both a built-in `Ingress` resource and a separate CRD that also happens to be named `Ingress` in a different API group. Your `match.resources.kinds` entry `- Ingress` is ambiguous. How do you disambiguate it?
*   **A)** Add a second `kinds` entry with just the API group name, e.g. `- networking.k8s.io`.
*   **B)** Qualify the entry as `group/version/Kind`, e.g. `- networking.k8s.io/v1/Ingress`.
*   **C)** Use `apiVersion` instead of `kinds` in the `match` block.
*   **D)** It cannot be disambiguated; only one `Ingress`-named resource may exist per cluster.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** When a bare Kind name is ambiguous across API groups, `kinds` entries can be fully qualified as `group/version/Kind`, giving Kyverno the exact API resource to match rather than any resource sharing that Kind string.
*   **Why others are incorrect:**
    *   *Option A* invents a syntax `kinds` does not support — a bare group name is not a valid `kinds` entry.
    *   *Option C* — `match.resources` has no top-level `apiVersion` field; qualification happens inside the `kinds` entry itself.
    *   *Option D* is wrong — Kubernetes explicitly supports the same Kind name existing in different API groups; that is exactly why the qualified form exists.
</details>

---

### Question 2
You write `resources.names: ["*-secrets"]` on a `ConfigMap`-scoped rule, intending to catch every `ConfigMap` that holds sensitive data. A teammate creates a `ConfigMap` named `db-password` holding an actual database password. What happens?
*   **A)** The rule catches it anyway, because Kyverno scans `ConfigMap` values for the word "secret".
*   **B)** The rule does not evaluate it at all — `names` matches only against `metadata.name`, and `db-password` does not end in `-secrets`.
*   **C)** The rule catches it, because `*-secrets` is treated as a regular expression matching any sensitive-sounding name.
*   **D)** The rule renames the `ConfigMap` to end in `-secrets` before evaluating it.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `name`/`names` wildcard matching operates purely on the string in `metadata.name`. It has no awareness of the object's actual content, so a `ConfigMap` named `db-password` — regardless of what it stores — is simply outside the scope of a rule filtered to `*-secrets`.
*   **Why others are incorrect:**
    *   *Option A* invents content-scanning behavior `names` does not perform.
    *   *Option C* — Kyverno's wildcard is a simple glob (`*` = any sequence of characters), not a regular expression engine.
    *   *Option D* — Kyverno's `match`/`exclude` selection never mutates the resource being evaluated.
</details>

---

### Question 3
A rule uses `resources.namespaces: ["shop-prod"]`. Six months later, a new namespace `shop-prod-eu` is created for a European region. Does the rule automatically apply to `shop-prod-eu`?
*   **A)** Yes, because `namespaces` entries are wildcard-capable by default even without an explicit `*`.
*   **B)** No — `namespaces` is a static literal list; `shop-prod-eu` is a different string than `shop-prod` and must be added explicitly (or the entry rewritten with a wildcard).
*   **C)** Yes, because Kyverno treats any namespace sharing a prefix as automatically in scope.
*   **D)** No, and it never can be added without deleting and recreating the policy.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `resources.namespaces` is a static, literal list. `shop-prod-eu` is a distinct string from `shop-prod`, so it is not in scope unless the policy is edited — either adding `shop-prod-eu` explicitly or rewriting the entry as a wildcard like `"shop-prod*"`.
*   **Why others are incorrect:**
    *   *Option A* is wrong — wildcards in `namespaces` entries must be written explicitly (`*`); a plain literal string is matched exactly.
    *   *Option C* invents automatic prefix-based scope expansion that does not exist.
    *   *Option D* is wrong — `kubectl edit clusterpolicy` (or reapplying updated YAML) can update the `namespaces` list at any time; nothing requires deletion and recreation.
</details>

---

### Question 4
A `ClusterPolicy` rule uses `namespaceSelector: {matchLabels: {env: prod}}`. Someone runs `kubectl label namespace shop-dev env=prod` for an unrelated reason. What is the immediate effect on this rule's scope?
*   **A)** None — `namespaceSelector` is evaluated only once, at the time the policy is applied.
*   **B)** The rule immediately begins applying to resources in `shop-dev` too, since its scope is read dynamically from live namespace labels.
*   **C)** Kyverno rejects the `kubectl label` command because it would change an existing policy's scope.
*   **D)** The rule stops applying to `shop-dev` entirely, since labeling triggers a namespace exclusion.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `namespaceSelector` reads the live labels on `Namespace` objects at evaluation time, not a snapshot taken when the policy was applied. The moment `shop-dev` carries `env: prod`, any rule scoped with `namespaceSelector: {matchLabels: {env: prod}}` begins applying to resources inside it — no policy edit required.
*   **Why others are incorrect:**
    *   *Option A* describes static `namespaces` list behavior, not `namespaceSelector`.
    *   *Option C* — Kyverno does not intercept or block unrelated `kubectl label namespace` commands based on policy scope.
    *   *Option D* inverts the actual effect — adding the matching label brings the namespace *into* scope, not out of it.
</details>

---

### Question 5
A rule sets both `namespaceSelector: {matchLabels: {env: prod}}` and `objectSelector: {matchLabels: {tier: frontend}}` inside the same `resources` block, matching `kinds: [Pod]`. A Pod is labeled `tier: frontend` and created in a namespace labeled `env: dev`. Does the rule evaluate this Pod?
*   **A)** Yes — `objectSelector` matching is sufficient on its own regardless of `namespaceSelector`.
*   **B)** No — both selectors sit inside the same `resources` block and are ANDed together; the namespace's `env: dev` label fails the `namespaceSelector` condition, so the rule does not evaluate this Pod even though its own labels match `objectSelector`.
*   **C)** Yes, because `objectSelector` always takes priority over `namespaceSelector` when both are present.
*   **D)** No, because `namespaceSelector` and `objectSelector` cannot legally coexist in the same `resources` block.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Fields inside one `resources` block are implicitly ANDed. `objectSelector` checks the Pod's own labels (satisfied here), while `namespaceSelector` checks the Namespace object's labels (not satisfied — the namespace is `env: dev`, not `env: prod`). Since both must hold, the rule does not evaluate this Pod.
*   **Why others are incorrect:**
    *   *Option A* and *Option C* both invent a priority/override relationship between the two selectors that does not exist — they are independent AND conditions.
    *   *Option D* is wrong — `namespaceSelector` and `objectSelector` are both valid, commonly combined fields within the same `resources` block.
</details>

---

### Question 6
You want a validate rule to run when a Pod is first created, but explicitly NOT re-run when that same Pod is later updated (for example, by a status patch). What should you set?
*   **A)** `operations: [CREATE]` in the rule's `match` block.
*   **B)** `background: false` on the rule.
*   **C)** `validationFailureAction: Audit` instead of `Enforce`.
*   **D)** `exclude.any.resources.operations: [UPDATE, DELETE]`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `operations` in the `match` block restricts which admission verbs a rule evaluates. Setting it to `[CREATE]` means only brand-new Pods are checked at admission time; subsequent `UPDATE` requests to the same object never re-trigger the rule.
*   **Why others are incorrect:**
    *   *Option B* controls periodic re-scanning of already-existing resources independent of admission, not which live admission operations the rule evaluates.
    *   *Option C* only changes whether a failure blocks or is merely logged — it does not change which operations are evaluated.
    *   *Option D* is a more roundabout (and non-idiomatic) way to try to express the same restriction that `match.resources.operations: [CREATE]` states directly; `exclude` is meant for carving exceptions out of an otherwise-broader match, not as the primary mechanism for operation scoping.
</details>

---

### Question 7
A rule's `match` block is:
```yaml
match:
  any:
  - resources:
      kinds: [Pod]
      namespaces: [ns-a]
  - resources:
      kinds: [Pod]
      namespaces: [ns-b]
```
A Pod is created in `ns-c`. Does the rule evaluate it?
*   **A)** Yes, because `any` means the rule applies everywhere except explicitly excluded namespaces.
*   **B)** No — `any` is an OR across the listed blocks; the Pod must satisfy at least one of them, and `ns-c` satisfies neither the `ns-a` nor the `ns-b` block.
*   **C)** Yes, because two `resources` blocks under `any` automatically union into "all namespaces except none."
*   **D)** No, but only because `any` requires exactly two blocks and a third namespace breaks that constraint.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `any` is a logical OR — the rule matches a resource if it satisfies at least one of the listed blocks. A Pod in `ns-c` satisfies neither the `ns-a` block nor the `ns-b` block, so the rule does not evaluate it.
*   **Why others are incorrect:**
    *   *Option A* and *Option C* both misread `any` as an implicit "everything not excluded" — `any` only ever expands scope to what is explicitly listed, never beyond it.
    *   *Option D* invents a nonexistent limit on how many blocks `any` may contain.
</details>

---

### Question 8
A human-facing guardrail rejects Pods without a `team` label, but your CI pipeline's `ServiceAccount` (`ci-deployer`) legitimately needs to create Pods without that label as part of an automated test harness. What is the most direct, idiomatic way to let only that identity bypass the rule?
*   **A)** Add `exclude.any.subjects: [{kind: ServiceAccount, name: ci-deployer, namespace: <ns>}]` to the rule.
*   **B)** Set `validationFailureAction: Audit` cluster-wide so nothing is ever blocked.
*   **C)** Remove the `match` block's `namespaces` filter so the rule applies more broadly.
*   **D)** Grant `ci-deployer` the `cluster-admin` ClusterRole so Kyverno's admission webhook skips it automatically.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `exclude.subjects` is exactly the mechanism designed for exempting one specific identity from an otherwise-applicable rule, without weakening the rule for anyone else.
*   **Why others are incorrect:**
    *   *Option B* removes enforcement for every requester, not just `ci-deployer` — far broader than intended.
    *   *Option C* widens the rule's scope, the opposite of what's needed, and does nothing to exempt a specific identity.
    *   *Option D* is wrong — RBAC permission level (even `cluster-admin`) does not make Kyverno's admission webhook skip a requester; webhook evaluation and RBAC authorization are separate systems, and only an explicit `subjects`/`roles`/`clusterRoles` exclusion in the policy itself changes what a rule evaluates.
</details>
