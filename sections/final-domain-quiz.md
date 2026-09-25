# KCA Applying Policies Certification Quiz

Welcome to the Final Domain Certification Quiz for the **ATS010: Applying Policies** curriculum. This comprehensive test contains **18 high-signal, scenario-based questions** covering all 6 modules across the 3 sections.

To simulate exam-style pressure:
*   Answer all 18 questions without consulting external documentation or the Kyverno CLI.
*   Allow yourself a maximum of **30 minutes** to complete the entire test.
*   Once finished, scroll to the very bottom to check the **Audit and Review Key** to trace any incorrect answers back to their exact section and module chapters.

---

## The Exam Simulator

### Question 1
You edit a `ClusterPolicy` manifest on disk to fix a `match` block, but never run `kubectl apply -f` again. What does the cluster enforce right now?
*   **A)** The fixed version, since Kyverno watches policy source files for changes.
*   **B)** Whatever was last successfully applied to the cluster — the local edit has no effect until re-applied.
*   **C)** Nothing, because any local edit immediately disables the live policy.
*   **D)** A merge of both versions, field by field.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `ClusterPolicy` is a Kubernetes object living in etcd, not a live pointer to a file on disk. The cluster only reflects the last successfully applied state.
*   **Why others are incorrect:** *A* invents filesystem-watching Kyverno doesn't do. *C* and *D* both assume a live coupling between a local file and a cluster object that doesn't exist.
</details>

---

### Question 2
A newly-applied `ClusterPolicy` has `validationFailureAction: Audit`. A Pod violating its rule is created. What happens immediately?
*   **A)** The Pod is rejected outright.
*   **B)** The Pod is admitted normally, and the violation is recorded in a `PolicyReport`/`ClusterPolicyReport` — nothing is blocked.
*   **C)** The Pod is admitted, then deleted seconds later by the background controller.
*   **D)** The Pod is automatically mutated into compliance.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Audit` admits and records — that is the entire mechanism.
*   **Why others are incorrect:** *A* describes `Enforce`. *C* invents destructive background behavior that doesn't exist. *D* confuses `validate` with `mutate`.
</details>

---

### Question 3
You need `Enforce` in one already-clean namespace while every other namespace stays on `Audit`, without maintaining two copies of the policy. What field is built for this?
*   **A)** `spec.background`
*   **B)** `spec.validationFailureActionOverrides`
*   **C)** `spec.schemaValidation`
*   **D)** `spec.applyRules`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `validationFailureActionOverrides` sets a different `validationFailureAction` per namespace (or namespace selector) from a single policy.
*   **Why others are incorrect:** *A* controls background re-scanning. *C* checks the policy's own shape at apply time. *D* decides how many rules in one policy run per resource — none scope enforcement mode per namespace.
</details>

---

### Question 4
A `ClusterPolicy` rule matches only `kinds: [Pod]`, yet after applying it you see extra `autogen-`-prefixed rules and a controller annotation. What is this?
*   **A)** A bug — the policy should contain exactly the rule you wrote.
*   **B)** Kyverno's autogen mechanism, automatically extending a Pod-scoped rule to the controllers that spawn Pods (Deployment, StatefulSet, DaemonSet, Job, CronJob).
*   **C)** Evidence the policy failed schema validation and Kyverno is retrying under alternate names.
*   **D)** Leftover state from a previous same-named policy.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Autogen is documented, deliberate behavior — one authored Pod-scoped rule protects the whole family of Pod-creating controllers.
*   **Why others are incorrect:** *A* and *C* misread expected behavior as a defect. *D* invents stale state for something regenerated fresh on every apply.
</details>

---

### Question 5
You want a Pod-scoped rule to apply to bare Pods only, never the Deployments/StatefulSets that would otherwise own them. What do you do?
*   **A)** Set `background: false`.
*   **B)** Set the `pod-policies.kyverno.io/autogen-controllers` annotation to `"none"`.
*   **C)** Add `exclude.resources.kinds: [Deployment, StatefulSet]`.
*   **D)** This cannot be disabled once a rule matches `Pod`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The `autogen-controllers` annotation set to `"none"` is the documented opt-out.
*   **Why others are incorrect:** *A* affects background re-scanning, not autogen. *C* is a no-op — the original rule never matched those kinds to begin with. *D* is wrong; the annotation exists specifically to make autogen optional.
</details>

---

### Question 6
A `PolicyException` exempting a specific Job from a resource-limits rule has no observable effect — matching Jobs are still blocked. What's the most likely cause?
*   **A)** `PolicyException` objects take up to 24 hours to activate.
*   **B)** PolicyExceptions are opt-in — `--enablePolicyException=true` (and a matching `--exceptionNamespace`) must be set on the Kyverno admission controller first.
*   **C)** `PolicyException` can only ever target `Pod` resources.
*   **D)** Exceptions must live in the `kyverno` namespace, never the workload's own namespace.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Without the admission controller's `--enablePolicyException=true` flag, a `PolicyException` object is accepted by the API server but simply has no effect.
*   **Why others are incorrect:** *A* invents a delay. *C* is wrong — any kind the underlying rule covers can be exempted. *D* is backwards — the exception must live in whatever namespace `--exceptionNamespace` names.
</details>

---

### Question 7
Your cluster has both a built-in `Ingress` and a CRD also named `Ingress` in a different API group. Your `match.resources.kinds` entry `- Ingress` is ambiguous. How do you fix it?
*   **A)** Add a second `kinds` entry naming just the API group.
*   **B)** Qualify the entry as `group/version/Kind`, e.g. `networking.k8s.io/v1/Ingress`.
*   **C)** Use `apiVersion` instead of `kinds` in the `match` block.
*   **D)** It can't be done; duplicate Kind names across groups aren't supported.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A fully-qualified `group/version/Kind` entry picks the exact API resource, resolving the ambiguity.
*   **Why others are incorrect:** *A* isn't valid `kinds` syntax. *C* — `match.resources` has no such field. *D* is wrong; the same Kind name legitimately existing across groups is exactly why qualification exists.
</details>

---

### Question 8
You write `resources.names: ["*-secrets"]` on a `ConfigMap` rule, hoping to catch anything holding sensitive data. A `ConfigMap` named `db-password` holds an actual password. Does the rule evaluate it?
*   **A)** Yes — Kyverno scans values for sensitive-sounding content.
*   **B)** No — `names` matches only `metadata.name` as a glob; `db-password` doesn't end in `-secrets`.
*   **C)** Yes — `*-secrets` behaves as a regular expression matching sensitive names.
*   **D)** The rule renames the ConfigMap before evaluating it.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `names` wildcard matching is purely a name-string glob — no content awareness at all.
*   **Why others are incorrect:** *A* invents content scanning. *C* — the wildcard is a glob, not regex. *D* — match/exclude never mutates anything.
</details>

---

### Question 9
A rule uses `resources.namespaces: ["shop-prod"]`. A new namespace `shop-prod-eu` is created later. Does the rule automatically cover it?
*   **A)** Yes — `namespaces` entries are wildcard-capable by default.
*   **B)** No — it's a static literal list; `shop-prod-eu` must be added explicitly or the entry rewritten as a wildcard.
*   **C)** Yes — Kyverno treats shared-prefix namespaces as automatically in scope.
*   **D)** No, and it can never be changed without deleting and recreating the policy.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `namespaces` is a static list matched literally unless a wildcard is explicitly written.
*   **Why others are incorrect:** *A* and *C* both invent automatic scope expansion. *D* is wrong — the policy can simply be re-applied with an updated list.
</details>

---

### Question 10
A rule uses `namespaceSelector: {matchLabels: {env: prod}}`. Someone later labels an unrelated namespace `shop-dev` with `env=prod`. What happens to the rule's scope?
*   **A)** Nothing — `namespaceSelector` is evaluated once, at apply time.
*   **B)** The rule immediately begins applying to `shop-dev` too, since scope is read live from namespace labels.
*   **C)** Kyverno rejects the label command to protect the existing policy's scope.
*   **D)** The rule stops applying to `shop-dev`, since labeling triggers exclusion.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `namespaceSelector` reads live namespace labels at evaluation time — no policy edit needed for scope to follow a relabel.
*   **Why others are incorrect:** *A* describes static `namespaces` behavior. *C* — Kyverno doesn't intercept unrelated label commands. *D* inverts the actual effect.
</details>

---

### Question 11
A rule sets both `namespaceSelector: {matchLabels: {env: prod}}` and `objectSelector: {matchLabels: {tier: frontend}}` in the same `resources` block, on `kinds: [Pod]`. A Pod labeled `tier: frontend` is created in a namespace labeled `env: dev`. Does the rule evaluate it?
*   **A)** Yes — `objectSelector` alone is sufficient.
*   **B)** No — the two selectors are ANDed; the namespace fails `env: prod`, so the rule never evaluates this Pod.
*   **C)** Yes — `objectSelector` always takes priority.
*   **D)** No — the two selectors can't legally coexist in one block.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Fields inside one `resources` block are implicitly ANDed together; both conditions must hold.
*   **Why others are incorrect:** *A* and *C* invent a priority relationship that doesn't exist. *D* is wrong — combining both is a common, valid pattern.
</details>

---

### Question 12
You need a validate rule to run on Pod creation but never re-run on a later status-only `UPDATE`. What setting achieves this?
*   **A)** `operations: [CREATE]` in the `match` block.
*   **B)** `background: false`.
*   **C)** `validationFailureAction: Audit`.
*   **D)** `exclude.any.resources.operations: [UPDATE, DELETE]`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `match.resources.operations` restricts which admission verbs a rule evaluates at all; `[CREATE]` limits it to first-time creation.
*   **Why others are incorrect:** *B* governs re-scanning of existing resources, unrelated to admission operations. *C* only changes block-vs-log behavior. *D* is a roundabout, non-idiomatic way to approximate the same restriction.
</details>

---

### Question 13
A rule's `match.any` lists two blocks: one for `kinds: [Pod], namespaces: [ns-a]`, another for `kinds: [Pod], namespaces: [ns-b]`. A Pod is created in `ns-c`. Does the rule evaluate it?
*   **A)** Yes — `any` means "everywhere except explicitly excluded."
*   **B)** No — `any` is an OR across the listed blocks, and `ns-c` satisfies neither.
*   **C)** Yes — two blocks under `any` union into "all namespaces."
*   **D)** No, but only because `any` is limited to exactly two blocks.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `any` only expands scope to what's explicitly listed — never beyond it.
*   **Why others are incorrect:** *A* and *C* both misread `any` as an implicit catch-all. *D* invents a block-count limit that doesn't exist.
</details>

---

### Question 14
A human-facing guardrail requires a `team` label on every Pod, but a CI `ServiceAccount` (`ci-deployer`) legitimately needs to bypass it. What's the idiomatic fix?
*   **A)** Add `exclude.any.subjects: [{kind: ServiceAccount, name: ci-deployer, namespace: <ns>}]`.
*   **B)** Set `validationFailureAction: Audit` cluster-wide.
*   **C)** Remove the rule's `namespaces` filter.
*   **D)** Grant `ci-deployer` the `cluster-admin` ClusterRole.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** `exclude.subjects` exempts one specific identity without weakening the rule for anyone else.
*   **Why others are incorrect:** *B* removes enforcement for everyone. *C* widens scope instead of narrowing an exemption. *D* is wrong — RBAC authorization and Kyverno admission evaluation are separate systems; a ClusterRole grant does not make the webhook skip a requester.
</details>

---

### Question 15
A `ClusterPolicy` sets `failurePolicy: Fail` (the default) and Kyverno's admission controller becomes completely unreachable. What happens to a request that would have matched this policy?
*   **A)** It is admitted anyway.
*   **B)** It is denied — `Fail` closes the door when the webhook can't answer.
*   **C)** The API server retries indefinitely.
*   **D)** It's queued and replayed once Kyverno recovers.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `failurePolicy: Fail` is "fail closed" — unreachable or timed-out means denied.
*   **Why others are incorrect:** *A* describes `Ignore`. *C* and *D* invent retry/queue mechanisms Kubernetes admission control doesn't have.
</details>

---

### Question 16
By default, a brand-new `ClusterPolicy` with a `generate` rule is applied to a cluster with 40 pre-existing namespaces. What happens to those 40 namespaces?
*   **A)** They're all immediately backfilled, since `generate` rules always run cluster-wide on apply.
*   **B)** Nothing — `generate` rules are forward-only by default; the 40 existing namespaces are untouched unless `generateExisting: true` is also set.
*   **C)** They're deleted and recreated to re-trigger the rule.
*   **D)** Kyverno queues a one-time job to backfill them automatically within 24 hours.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `generate` rules react to admission events on trigger resources; pre-existing resources generated no such event for this new policy, so they're skipped unless `generateExisting: true` opts in.
*   **Why others are incorrect:** *A* is the exact misconception `generateExisting` exists to correct. *C* is destructive and not how Kyverno works. *D* invents an automatic delayed mechanism that doesn't exist.
</details>

---

### Question 17
A `ClusterPolicy` has `spec.applyRules: "One"` and three rules in order: `rule-a`, `rule-b`, `rule-c`. A resource matches both `rule-a` and `rule-c` but not `rule-b`. Which rule(s) run?
*   **A)** All three — `applyRules` only affects `generate` rules.
*   **B)** Only `rule-a` — Kyverno stops at the first matching rule in list order.
*   **C)** `rule-a` and `rule-c`, since those are the ones that match.
*   **D)** Only `rule-c`, evaluated last and "winning."

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `applyRules: "One"` evaluates rules in order and stops after the first one that matches and runs.
*   **Why others are incorrect:** *A* — `applyRules` applies to every rule type. *C* describes the default `"All"` behavior. *D* inverts actual precedence.
</details>

---

### Question 18
A `mutate` rule uses a `targets` block to patch existing Deployments cluster-wide, and the policy sets `mutateExistingOnPolicyUpdate: true`. What triggers the retroactive sweep of already-existing Deployments?
*   **A)** Only the periodic background-scan interval, exactly like a validate rule with `background: true`.
*   **B)** The policy itself being created or updated — at that moment Kyverno patches every currently-matching resource, not just future admissions.
*   **C)** Nothing automatic — an administrator must manually re-apply every target.
*   **D)** Only the first cluster reboot after the policy is applied.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `mutateExistingOnPolicyUpdate: true` combined with `mutate.targets` makes Kyverno sweep and patch matching existing resources whenever the policy is created or updated.
*   **Why others are incorrect:** *A* conflates this with an unrelated background-scan/reporting mechanism. *C* defeats the purpose of the setting. *D* invents a reboot-triggered mechanism with no basis in how Kyverno or Kubernetes works.
</details>

---

## Audit and Review Key

| Question | Correct Answer | Review Section |
| :--- | :--- | :--- |
| 1 | B | [Section 010, Module 1.1](./section-010/module-01/course-01-applying-clusterpolicy-and-policy-with-kubectl.md) |
| 2 | B | [Section 010, Module 1.2](./section-010/module-01/course-02-enforce-vs-audit-at-apply-time.md) |
| 3 | B | [Section 010, Module 1.2](./section-010/module-01/course-02-enforce-vs-audit-at-apply-time.md) |
| 4 | B | [Section 010, Module 2.2](./section-010/module-02/course-02-autogen-and-policyexceptions.md) |
| 5 | B | [Section 010, Module 2.2](./section-010/module-02/course-02-autogen-and-policyexceptions.md) |
| 6 | B | [Section 010, Module 2.2](./section-010/module-02/course-02-autogen-and-policyexceptions.md) |
| 7 | B | [Section 020, Module 1.1](./section-020/module-01/course-01-selecting-by-kind-name-and-wildcards.md) |
| 8 | B | [Section 020, Module 1.1](./section-020/module-01/course-01-selecting-by-kind-name-and-wildcards.md) |
| 9 | B | [Section 020, Module 1.2](./section-020/module-01/course-02-namespaces-and-namespaceselector.md) |
| 10 | B | [Section 020, Module 1.2](./section-020/module-01/course-02-namespaces-and-namespaceselector.md) |
| 11 | B | [Section 020, Module 2.1](./section-020/module-02/course-01-objectselector-and-operations.md) |
| 12 | A | [Section 020, Module 2.1](./section-020/module-02/course-01-objectselector-and-operations.md) |
| 13 | B | [Section 020, Module 2.2](./section-020/module-02/course-02-subjects-roles-clusterroles-and-any-all.md) |
| 14 | A | [Section 020, Module 2.2](./section-020/module-02/course-02-subjects-roles-clusterroles-and-any-all.md) |
| 15 | B | [Section 030, Module 1.1](./section-030/module-01/course-01-failurepolicy-and-webhooktimeoutseconds.md) |
| 16 | B | [Section 030, Module 2.2](./section-030/module-02/course-02-generateexisting-and-mutateexistingonpolicyupdate.md) |
| 17 | B | [Section 030, Module 2.1](./section-030/module-02/course-01-applyrules-all-vs-one.md) |
| 18 | B | [Section 030, Module 2.2](./section-030/module-02/course-02-generateexisting-and-mutateexistingonpolicyupdate.md) |
