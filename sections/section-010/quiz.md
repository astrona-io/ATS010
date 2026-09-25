# Section 010 Knowledge Check: Applying Policy in Cluster

Test your understanding of applying and inspecting policies with kubectl, Enforce vs Audit semantics, validationFailureActionOverrides, background scanning, autogen, and PolicyExceptions.

---

## Scenario-Based Questions

### Question 1
You edit a `ClusterPolicy` YAML file on disk to fix a bug in its `match` block, but forget to run `kubectl apply -f` afterward. What does the cluster actually enforce?
*   **A)** The fixed version, because Kyverno watches the filesystem for changes.
*   **B)** Whatever was last successfully applied to the cluster — your local file edit has no effect until you re-apply it.
*   **C)** Nothing — Kyverno automatically disables a policy the moment its source file changes.
*   **D)** Both versions simultaneously, merged field by field.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A `ClusterPolicy` is a Kubernetes resource stored in etcd, not a live pointer to a file. The cluster only ever reflects what was last successfully `kubectl apply`'d (or `create`'d/`edit`'d) — a local file edit is inert until you re-run `kubectl apply -f`.
*   **Why others are incorrect:**
    *   *Option A* invents a filesystem-watching mechanism Kyverno does not have.
    *   *Option C* is wrong — nothing about editing a local file affects a live cluster object.
    *   *Option D* is wrong — there is no field-by-field merge between a file and a cluster object outside of what `kubectl apply` itself does when you actually run it.
</details>

---

### Question 2
You `kubectl apply -f` a `ClusterPolicy` file that has both a `validate` block and a `mutate` block under the same rule name — a shape Kyverno's schema does not allow. What happens?
*   **A)** The policy is accepted, but only the `validate` block is ever evaluated.
*   **B)** The `kubectl apply` command itself fails — Kyverno's own admission webhook for policy objects rejects the malformed policy before it ever becomes live.
*   **C)** The policy is accepted and applies both actions in the order they're written.
*   **D)** The policy is accepted but immediately shows as `NotReady` while running normally in Audit mode.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Kyverno validates policy objects against its own schema at apply time via its admission webhook for policy CRDs. A rule combining two action types in one entry is invalid, so the `kubectl apply` call fails immediately with an admission error — the policy never becomes live at all.
*   **Why others are incorrect:**
    *   *Option A* and *Option C* both assume the malformed policy gets accepted in some partial or combined form, which contradicts schema validation rejecting it outright.
    *   *Option D* invents a "NotReady but still running" state that doesn't apply to a policy object that failed admission and was never created.
</details>

---

### Question 3
A newly-applied `ClusterPolicy` has `validationFailureAction: Audit`. A Pod is created that violates its rule. What is true immediately after?
*   **A)** The Pod is rejected and never created.
*   **B)** The Pod is created normally, and the violation is recorded in a `PolicyReport`/`ClusterPolicyReport` — nothing is blocked.
*   **C)** The Pod is created, then deleted a few seconds later by Kyverno's background controller.
*   **D)** The Pod is created, and Kyverno automatically mutates it to become compliant.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `Audit` admits the resource and records the violation as a finding — that's the entire mechanism. No blocking, deleting, or auto-fixing happens.
*   **Why others are incorrect:**
    *   *Option A* describes `Enforce`, not `Audit`.
    *   *Option C* — Kyverno never deletes resources as a consequence of a validate rule's outcome.
    *   *Option D* confuses `validate` (accept/reject) with `mutate` (rewrite); a validate rule set to Audit never changes the resource.
</details>

---

### Question 4
You want to roll a policy out to `Enforce` in one namespace where you've already fixed every violation, while every other namespace stays on `Audit` a while longer — without maintaining two copies of the policy. What field is designed for exactly this?
*   **A)** `spec.background`
*   **B)** `spec.validationFailureActionOverrides`
*   **C)** `spec.schemaValidation`
*   **D)** `spec.failurePolicy`

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** `validationFailureActionOverrides` lets a single policy set a different `validationFailureAction` per namespace (or namespace selector), which is exactly the staged, namespace-by-namespace rollout described.
*   **Why others are incorrect:**
    *   *Option A* controls whether pre-existing resources are periodically re-scanned, not per-namespace enforcement mode.
    *   *Option C* and *Option D* are unrelated policy-level settings covered in Section 030, not scoping mechanisms for `validationFailureAction`.
</details>

---

### Question 5
A `ClusterPolicy` has `background: true` and `validationFailureAction: Audit`. It's applied to a cluster with three Deployments that already violate the rule. What happens to those three Deployments?
*   **A)** They are deleted immediately by the background controller.
*   **B)** Nothing happens to them at admission time (they already exist); the background scan evaluates them and records findings in a `PolicyReport`/`ClusterPolicyReport`, without blocking or altering them.
*   **C)** They are automatically mutated to become compliant.
*   **D)** They are unaffected because `background: true` only applies to `mutate` and `generate` rules.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Background scanning periodically re-evaluates already-existing resources against `validate` rules and records findings — it never blocks, deletes, or mutates.
*   **Why others are incorrect:**
    *   *Option A* and *Option C* both invent destructive or auto-remediating behavior background scanning does not have.
    *   *Option D* inverts the truth — background scanning is a `validate`-rule mechanism; `mutate`/`generate` have their own, separate "existing resource" settings (`mutateExistingOnPolicyUpdate`, `generateExisting`).
</details>

---

### Question 6
You write a `ClusterPolicy` rule matching `kinds: [Pod]` only, expecting it to also protect Deployments in your cluster. After applying it, you inspect it with `kubectl get clusterpolicy <name> -o yaml` and see extra rules prefixed `autogen-` and an annotation naming several controller kinds. What is this?
*   **A)** A bug — the policy should only ever contain the rule you wrote.
*   **B)** Kyverno's autogen mechanism, which automatically extends a Pod-scoped rule to also admission-check the Pod-template-owning controllers (Deployment, StatefulSet, DaemonSet, Job, CronJob, etc.).
*   **C)** Evidence that the policy failed validation and Kyverno is retrying with alternate rule names.
*   **D)** A leftover from a previous policy with the same name that was never fully deleted.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Autogen is a deliberate, documented Kyverno feature: a `Pod`-scoped rule is automatically mirrored into `autogen-`-prefixed rules covering the controllers that actually spawn Pods, so your one authored rule protects Deployments and friends too, not just bare Pods.
*   **Why others are incorrect:**
    *   *Option A* and *Option C* both misread expected, documented behavior as a defect.
    *   *Option D* invents a stale-state explanation for something that is generated fresh on every apply.
</details>

---

### Question 7
You want a specific Pod-scoped rule to apply *only* to bare Pods, never to the Deployments/StatefulSets/etc. that would otherwise own them. What do you do?
*   **A)** Set `background: false` on the rule.
*   **B)** Set the `pod-policies.kyverno.io/autogen-controllers` annotation to `"none"` on the policy.
*   **C)** Add `exclude.resources.kinds: [Deployment, StatefulSet, DaemonSet]` to the rule.
*   **D)** This cannot be done — autogen is always mandatory once a rule matches `Pod`.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Setting the `pod-policies.kyverno.io/autogen-controllers` annotation to `"none"` disables autogen for that policy, leaving the rule scoped exactly as written — bare Pods only.
*   **Why others are incorrect:**
    *   *Option A* controls background re-scanning of existing resources, not autogen.
    *   *Option C* is redundant and doesn't actually prevent autogen rule generation — autogen operates on the original `match`, and excluding controller kinds from a Pod-scoped rule's `match` has no effect since the rule never matched those kinds directly in the first place.
    *   *Option D* is wrong — the annotation exists specifically to make autogen optional.
</details>

---

### Question 8
You create a `PolicyException` object exempting a specific Job from a resource-limits rule, but non-compliant Jobs matching that exception are still being blocked exactly as before. What is the most likely cause?
*   **A)** `PolicyException` objects take up to 24 hours to take effect.
*   **B)** PolicyExceptions are disabled by default; `--enablePolicyException=true` (and a matching `--exceptionNamespace`) must be set on the Kyverno admission controller first.
*   **C)** `PolicyException` can only exempt `Pod` resources, never `Job` resources.
*   **D)** The exception needs to be created in the `kyverno` namespace, never in the workload's own namespace.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** PolicyExceptions are opt-in. Without `--enablePolicyException=true` set on `kyverno-admission-controller`, the object is accepted by the API server but has no effect. `--exceptionNamespace` additionally restricts which namespace's exceptions are honored — an exception outside that namespace is ignored even with the feature enabled.
*   **Why others are incorrect:**
    *   *Option A* invents a delay that doesn't exist; once enabled, exceptions apply immediately.
    *   *Option C* is wrong — `PolicyException` can match any resource kind the underlying rule applies to.
    *   *Option D* is backwards — an exception must live in whatever namespace `--exceptionNamespace` names, which is commonly the workload's own namespace, not necessarily `kyverno`.
</details>
