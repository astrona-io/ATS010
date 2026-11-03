# Section 020: Resource Selection

Every policy is only as good as its scope. A rule that applies too broadly blocks work it was never meant to touch; a rule that applies too narrowly leaves a gap a careless deploy can walk through. This section is about the `match`/`exclude` block that decides that scope, field by field.

You go beyond basic `kinds`/`namespaces` filtering and learn every axis Kyverno gives you: kind (including `group/version/Kind` and subresources such as `Pod/exec`), name and wildcard pattern, static `namespaces` versus dynamic `namespaceSelector`, annotations, the resource's own labels via `selector`, admission `operations`, and the requester's identity via `subjects`, `roles` and `clusterRoles`. All of it is tied together with `any`/`all` OR/AND logic and the rule that `exclude` always wins.

> The labs in this section are UNTESTED - built from static checks only; not yet booted.

---

## What You Will Master

*   **Kinds, Names & Namespaces:** qualifying `kinds`, `name` vs `names`, what `*` and `?` match, static vs dynamic namespace scope, annotations, exclude precedence and the AND trap, and `Policy` vs `ClusterPolicy`.
*   **Identity & Operation Selection:** scoping to a resource's own labels with `selector` (not `namespaceSelector`), restricting `operations`, selecting or excluding by `subjects`/`roles`/`clusterRoles` (with `background: false`), `any`/`all` combinations, and a fixed order for debugging a rule that did or did not match.

---

## The Learning & Lab Path

Two modules, each with a playground and a graded lab on a kind cluster, then a capstone.

### 1. match/exclude Fundamentals: Kinds, Names & Namespaces
*   **Module Reader:** **[Module 1](./module-01/course.md)**, with a playground launched from the landing page
    1. [Selecting by Kind, Name & Wildcards](./module-01/course-01-selecting-by-kind-name-and-wildcards.md)
    2. [Namespaces & namespaceSelector](./module-01/course-02-namespaces-and-namespaceselector.md)
    3. [Annotations, Exclude Precedence & Policy Scope](./module-01/course-03-annotations-exclude-precedence-and-policy-scope.md)
    4. [Summary](./module-01/course-04-summary.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Require a `security-reviewed` annotation on public-facing Ingresses only in namespaces labeled `env: prod`, and prove it blocks, admits or ignores resources by name pattern and namespace label.

### 2. Selecting by Identity & Operation
*   **Module Reader:** **[Module 2](./module-02/course.md)**, with a playground launched from the landing page
    1. [selector & Operations](./module-02/course-01-selector-and-operations.md)
    2. [subjects, roles, clusterRoles & any/all](./module-02/course-02-subjects-roles-clusterroles-and-any-all.md)
    3. [Debugging Why a Rule Did or Did Not Match](./module-02/course-03-debugging-why-a-rule-did-or-did-not-match.md)
    4. [Summary](./module-02/course-04-summary.md)
*   **Practice Lab Sandbox:** **`sections/section-020/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Restrict container images on label-selected Pods with `selector`, exclude a CI ServiceAccount with a `subjects`-based `exclude`, and prove it with `kubectl --as` impersonation.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-020/capstone/labs/lab-01` (Resource Selection Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Combine name wildcards, `namespaceSelector`, `selector`, `operations` and a `subjects`-based exclude in one policy, and prove each axis independently takes a resource out of (or into) scope.

---

## Ready for Assessment?

*   **[Take the Section 020 Knowledge Check Quiz](./quiz.yaml)**
