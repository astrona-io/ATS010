# Section 020: Resource Selection

Welcome to the Resource Selection domain. Every policy you write is only as good as its scope: a rule that applies too broadly enforces a guardrail where it shouldn't and blocks work it was never meant to touch; a rule that applies too narrowly leaves a gap an attacker or a careless deploy can walk straight through. This section is entirely about the `match`/`exclude` block that decides that scope — precisely, field by field.

You'll go beyond the basic `kinds`/`namespaces` filtering you've already seen and learn every axis Kyverno gives you to select (or exclude) a resource: by kind and qualified `group/version/Kind`, by name and wildcard pattern, by static namespace list versus dynamic `namespaceSelector`, by the resource's own labels via `objectSelector`, by admission operation, and by the requester's own identity via `subjects`, `roles`, and `clusterRoles` — all tied together with `any`/`all` OR/AND logic.

---

## What You Will Master

By completing this section, you will acquire two core Kyverno competencies:
*   **Kinds, Names & Namespaces:** Qualifying ambiguous `kinds` entries, the difference between `name` and `names`, exactly what the `*` wildcard does and doesn't guarantee, and the static-vs-dynamic distinction between `resources.namespaces` and `namespaceSelector`.
*   **Identity & Operation Selection:** Scoping a rule to a resource's own labels with `objectSelector` (and not confusing it with `namespaceSelector`), restricting a rule to specific admission `operations`, selecting or excluding by requester identity with `subjects`/`roles`/`clusterRoles`, and combining independent selection blocks with `any`/`all`.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each paired with a dedicated graded lab on a kind Kubernetes cluster. The section concludes with a comprehensive Capstone Integration Challenge:

### 1. match/exclude Fundamentals: Kinds, Names & Namespaces
*   **Module Reader:** **[Module 1: match/exclude Fundamentals: Kinds, Names & Namespaces](./module-01/course.md)**
    1. [Selecting by Kind, Name & Wildcards](./module-01/course-01-selecting-by-kind-name-and-wildcards.md)
    2. [Namespaces & namespaceSelector](./module-01/course-02-namespaces-and-namespaceselector.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Write a `ClusterPolicy` that requires a `security-reviewed` annotation on public-facing Ingresses only in namespaces labeled `env: prod`, and prove it blocks, admits, or ignores resources based purely on name pattern and namespace label.

### 2. Selecting by Identity & Operation
*   **Module Reader:** **[Module 2: Selecting by Identity & Operation](./module-02/course.md)**
    1. [objectSelector & Operations](./module-02/course-01-objectselector-and-operations.md)
    2. [subjects, roles, clusterRoles & any/all](./module-02/course-02-subjects-roles-clusterroles-and-any-all.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Restrict container images on label-selected Pods with `objectSelector`, then exclude a CI ServiceAccount from that same rule with a `subjects`-based `exclude` block, and prove the exclusion via `kubectl --as` impersonation.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-020/capstone/labs/lab-01` (Resource Selection Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Combine name wildcards, `namespaceSelector`, `objectSelector`, `operations`, and a `subjects`-based exclude into a single policy, and prove each axis independently takes a resource out of (or into) scope.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 020 Knowledge Check Quiz](./quiz.md)**
