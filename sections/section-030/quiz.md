# Section 030 Knowledge Check: Common Policy Settings

Test your understanding of `failurePolicy`, `webhookTimeoutSeconds`, `schemaValidation`, `applyRules`, `generateExisting`, and `mutateExistingOnPolicyUpdate`.

---

## Scenario-Based Questions

### Question 1
A `ClusterPolicy` sets `failurePolicy: Fail` (the default). Kyverno's admission controller becomes completely unreachable due to a bad rollout. What happens to a request that would have matched this policy's rules?
*   **A)** It is admitted anyway, since Kyverno can't be reached to say otherwise.
*   **B)** It is denied — `Fail` means the API server closes the door when it can't get an answer from the webhook.
*   **C)** The API server retries indefinitely until Kyverno comes back.
*   **D)** The request is queued and replayed once Kyverno's admission controller recovers.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `failurePolicy: Fail` is "fail closed" — if the webhook is unreachable or times out, the API server denies the request rather than letting it through unchecked.
*   **Why others are incorrect:**
    *   *Option A* describes `failurePolicy: Ignore`, the opposite setting.
    *   *Option C* — the API server does not retry indefinitely; it waits up to `webhookTimeoutSeconds` and then applies `failurePolicy`.
    *   *Option D* invents a request-queuing mechanism Kubernetes admission control does not have.
</details>

---

### Question 2
Why might a team deliberately choose `failurePolicy: Ignore` for a particular policy instead of the default `Fail`?
*   **A)** `Ignore` makes Kyverno evaluate rules faster than `Fail`.
*   **B)** `Ignore` keeps the cluster available during a Kyverno outage, accepting that enforcement for that policy silently stops during the outage, as a tradeoff for that availability.
*   **C)** `Ignore` is required for any policy using a `generate` rule.
*   **D)** `Ignore` disables `webhookTimeoutSeconds`, so the setting no longer matters.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `failurePolicy: Ignore` ("fail open") trades away guaranteed enforcement during an outage in exchange for not blocking unrelated cluster activity if Kyverno itself becomes unreachable — a deliberate availability-over-strictness tradeoff for lower-stakes policies.
*   **Why others are incorrect:**
    *   *Option A* — `failurePolicy` has no effect on evaluation speed while Kyverno is healthy; it only changes behavior on timeout/unreachability.
    *   *Option C* — `generate` rules have no special `failurePolicy` requirement.
    *   *Option D* — `webhookTimeoutSeconds` still applies; `failurePolicy` only decides what happens once that timeout is hit.
</details>

---

### Question 3
What does `spec.webhookTimeoutSeconds` actually control?
*   **A)** How long Kyverno's background scan controller waits between re-scan cycles.
*   **B)** How long the API server waits for Kyverno's admission response before treating the call as failed (and then applying `failurePolicy`).
*   **C)** How long a `generate` rule waits before creating its target resource.
*   **D)** The TTL of a cached policy decision.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `webhookTimeoutSeconds` sets the window (default 10, max 30) the API server gives the webhook call to Kyverno before deciding it has failed, at which point `failurePolicy` takes over.
*   **Why others are incorrect:**
    *   *Option A* describes background-scan scheduling, an unrelated concept with no direct tie to this field.
    *   *Option C* — `generate` rules act on admission, not after some independent delay.
    *   *Option D* — Kyverno does not cache admission decisions with a TTL controlled by this field.
</details>

---

### Question 4
What does `spec.schemaValidation: false` actually change?
*   **A)** It relaxes how strictly `validate` rules check other resources' shapes.
*   **B)** It disables Kyverno's own pre-flight check of the policy resource's shape against its internal schema at apply time — it has no effect on how the policy's rules evaluate other resources.
*   **C)** It allows `validate` and `mutate` blocks to be combined in the same rule.
*   **D)** It turns off `webhookTimeoutSeconds` entirely.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `schemaValidation` only governs whether Kyverno validates the *policy YAML itself* at apply time. Turning it off means a malformed policy might apply without an early error, but it does not touch how that policy's rules subsequently evaluate other resources.
*   **Why others are incorrect:**
    *   *Option A* confuses policy-shape validation with resource-pattern validation — two unrelated checks.
    *   *Option C* — combining `validate` and `mutate` in one rule remains invalid Kyverno rule structure regardless of this setting.
    *   *Option D* — the two settings are independent.
</details>

---

### Question 5
A `ClusterPolicy` has `spec.applyRules: "One"` and three rules listed in order: `rule-a`, `rule-b`, `rule-c`. A resource matches both `rule-a` and `rule-c`, but not `rule-b`. Which rule(s) actually run against it?
*   **A)** All three, since `applyRules` only affects `generate` rules.
*   **B)** Only `rule-a` — Kyverno stops at the first matching rule in list order.
*   **C)** `rule-a` and `rule-c`, since those are the two that match.
*   **D)** Only `rule-c`, since it is evaluated last and "wins."

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `applyRules: "One"` evaluates `spec.rules` in order and stops after the first rule that actually matches the resource runs — later rules, even ones that would otherwise match, are skipped for that resource.
*   **Why others are incorrect:**
    *   *Option A* — `applyRules` applies to all rule types, not just `generate`.
    *   *Option C* describes the default `applyRules: "All"` behavior, not `"One"`.
    *   *Option D* inverts the actual precedence — the first match wins, not the last.
</details>

---

### Question 6
By default (no special settings), a brand-new `ClusterPolicy` with a `generate` rule is applied to a cluster that already has 40 existing namespaces. What happens to those 40 namespaces?
*   **A)** They are all immediately backfilled with the generated resource, since `generate` rules always run against the whole cluster on apply.
*   **B)** Nothing — by default, `generate` rules only fire on admission of a new matching trigger resource going forward; the 40 existing namespaces are untouched unless `generateExisting: true` is also set.
*   **C)** They are all deleted and recreated so the generate rule can re-trigger on them.
*   **D)** Kyverno queues a one-time background job that runs the rule against them within 24 hours automatically.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `generate` rules are forward-only by default — they react to admission events on trigger resources. Pre-existing resources generated no admission event for this new policy to react to, so they're skipped unless `generateExisting: true` explicitly opts into a retroactive backfill.
*   **Why others are incorrect:**
    *   *Option A* is the exact misconception `generateExisting` exists to fix — it is not automatic.
    *   *Option C* is destructive and not how Kyverno works.
    *   *Option D* invents an automatic delayed-backfill mechanism Kyverno does not have.
</details>

---

### Question 7
A team sets `generateExisting: true` on a policy that only contains `mutate` rules (no `generate` rules at all). What effect does this have?
*   **A)** None — `generateExisting` only affects `generate` rules; it does nothing for a policy with no `generate` rules.
*   **B)** It silently converts the `mutate` rules into `generate` rules.
*   **C)** It causes the policy to fail `schemaValidation` and be rejected at apply time.
*   **D)** It automatically enables `mutateExistingOnPolicyUpdate` as well.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `generateExisting` and `mutateExistingOnPolicyUpdate` are two separate fields governing two separate rule types. Setting `generateExisting` on a policy with no `generate` rules simply has nothing to act on.
*   **Why others are incorrect:**
    *   *Option B* — Kyverno never reinterprets one rule action type as another.
    *   *Option C* — this is a valid, if inert, field combination; it does not fail schema validation.
    *   *Option D* — the two settings are independent; setting one never implicitly sets the other.
</details>

---

### Question 8
A `mutate` rule uses a `targets` block to patch existing `Deployment` resources across the cluster, and the policy sets `mutateExistingOnPolicyUpdate: true`. What triggers Kyverno to sweep and patch those already-existing Deployments?
*   **A)** Only the periodic background-scan interval, exactly like a validate rule with `background: true`.
*   **B)** The policy itself being created or updated — at that moment, Kyverno reaches out to every resource currently matching `targets` and patches it, not just resources admitted going forward.
*   **C)** Nothing automatic — an administrator must manually re-apply every target Deployment.
*   **D)** Only the first time the cluster is rebooted after the policy is applied.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `mutateExistingOnPolicyUpdate: true` combined with a `mutate.targets` block makes Kyverno retroactively sweep and patch matching existing resources whenever the policy is created or updated — the `mutate` analogue of `generateExisting`.
*   **Why others are incorrect:**
    *   *Option A* conflates this with background scanning of validate rules, an unrelated mechanism used for reporting, not mutation.
    *   *Option C* is wrong — the whole point of the setting is to automate exactly that sweep.
    *   *Option D* invents a reboot-triggered mechanism that does not exist; Kubernetes clusters and Kyverno have no such concept tied to this setting.
</details>
