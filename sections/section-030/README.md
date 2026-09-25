# Section 030: Common Policy Settings for Kyverno Rules

Welcome to the final section of the Applying Policies domain. Writing a correct rule is only part of running Kyverno in production — this section covers the settings that decide how resilient, how strict, and how retroactive a policy actually is once it's live.

None of the settings in this section change *what* a rule matches or *what action* it takes. They change how the policy behaves at its edges: what happens when Kyverno can't answer in time, whether a policy's rules run cumulatively or stop at the first match, and whether `generate`/`mutate` rules only ever look forward or can also reach back and fix up what's already in the cluster.

---

## What You Will Master

By completing this section, you will acquire two core Kyverno competencies:
*   **Policy-Level Settings:** The fail-open/fail-closed tradeoff between `failurePolicy: Fail` and `Ignore`, how `webhookTimeoutSeconds` bounds the API server's patience with the admission webhook, what `schemaValidation` actually checks, and when to deliberately set `background: false` on an admission-only rule.
*   **Rule-Level Settings:** How `applyRules: "One"` turns a rule list into a priority-ordered, mutually-exclusive decision instead of a cumulative stack, and how `generateExisting` and `mutateExistingOnPolicyUpdate` let `generate` and `mutate` rules retroactively reach resources that already existed before the policy did.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each paired with a dedicated graded lab on a kind Kubernetes cluster. The section concludes with a comprehensive Capstone Integration Challenge:

### 1. Policy-Level Settings: failurePolicy, Timeouts & Schema Validation
*   **Module Reader:** **[Module 1: Policy-Level Settings](./module-01/course.md)**
    1. [failurePolicy & webhookTimeoutSeconds](./module-01/course-01-failurepolicy-and-webhooktimeoutseconds.md)
    2. [schemaValidation & Policy-wide background](./module-01/course-02-schemavalidation-and-policy-wide-background.md)
*   **Practice Lab Sandbox:** **`sections/section-030/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Write two `ClusterPolicy` resources with opposite `failurePolicy` settings and matching `webhookTimeoutSeconds`, prove both enforce a required label identically while Kyverno is healthy, and explore how they diverge when the admission controller is unreachable.

### 2. Rule-Level Settings: applyRules, generateExisting & mutateExistingOnPolicyUpdate
*   **Module Reader:** **[Module 2: Rule-Level Settings](./module-02/course.md)**
    1. [applyRules: All vs One](./module-02/course-01-applyrules-all-vs-one.md)
    2. [generateExisting & mutateExistingOnPolicyUpdate](./module-02/course-02-generateexisting-and-mutateexistingonpolicyupdate.md)
*   **Practice Lab Sandbox:** **`sections/section-030/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Use `generateExisting: true` to retroactively backfill a default-deny `NetworkPolicy` into namespaces that existed before the policy did, then use `applyRules: "One"` to build a priority-ordered pair of mutate rules that produce exactly one cost-center outcome per namespace.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-030/capstone/labs/lab-01` (Common Policy Settings Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Connect the dots. Enforce resource limits with tuned `failurePolicy`/`webhookTimeoutSeconds`, retroactively generate an audit `ConfigMap` into a pre-existing namespace with `generateExisting`, and apply priority-ordered tier labeling with `applyRules: "One"`.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 030 Knowledge Check Quiz](./quiz.md)**
