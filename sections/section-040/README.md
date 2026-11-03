# Section 040: Applying Policy Types

A Kyverno policy changes a request, checks it, creates other objects, or cleans up old ones. This section teaches the four policy types you use most: `mutate`, `validate`, `generate` and cleanup. It ends with a short reading on `verifyImages`.

The section has two modules, each with a playground and a graded lab, and a capstone that joins the pieces.

---

## What You Will Master

*   **Mutate and validate:** write defaults with `patchStrategicMerge` and `patchesJson6902`, reject bad objects with `pattern` and `deny` rules, and prove why mutate rules run before validate rules.
*   **Generate and cleanup:** create resources when a namespace appears, choose between inline data and `clone`, decide on `synchronize`, give the Kyverno controllers the RBAC they need, and delete expired objects on a schedule.
*   **Image verification (concept):** read a `verifyImages` rule and explain attestors, digests and `Audit` against `Enforce`.

---

## The Learning & Lab Path

### 1. Applying Validate And Mutate Policies
*   **Module Reader:** **[Module 1: Applying Validate And Mutate Policies](./module-01/course.md)**
    1. [Mutate Rules With patchStrategicMerge And patchesJson6902](./module-01/course-01-mutate-rules.md)
    2. [Validate Rules, Deny Rules And Ordering](./module-01/course-02-validate-rules-and-order.md)
    3. [Summary](./module-01/course-03-summary.md)
*   **Playground (free exploration, no grading):** `sections/section-040/module-01/playground` (environment name `ats-010-playground-040-01`; the module reader launches it)
*   **Practice Lab:** **`sections/section-040/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Add pod defaults with a merge patch and a JSON patch, require an owner label and block `:latest` images, and deny the deletion of protected ConfigMaps.

### 2. Applying Generate And Cleanup Policies
*   **Module Reader:** **[Module 2: Applying Generate And Cleanup Policies](./module-02/course.md)**
    1. [Generate Rules, Synchronize And Clone](./module-02/course-01-generate-rules.md)
    2. [Cleanup Policies And The Cleanup Controller](./module-02/course-02-cleanup-policies.md)
    3. [Image Verification Overview](./module-02/course-03-image-verification-overview.md)
    4. [Summary](./module-02/course-04-summary.md)
*   **Playground (free exploration, no grading):** `sections/section-040/module-02/playground` (environment name `ats-010-playground-040-02`; the module reader launches it)
*   **Practice Lab:** **`sections/section-040/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Grant the background and cleanup controllers the rights they need, generate a quota, a network policy and a cloned ConfigMap for labelled namespaces, and delete expired ConfigMaps on a schedule. Image verification has no lab.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-040/capstone/labs/lab-01` (Policy Types Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-040/capstone/labs/lab-01
    ```
*   **Status:** UNTESTED - built from static checks only; not yet booted (as are the two module labs above).
*   **Hands-on Objective:** Onboard a namespace with generated defaults, add a default cost-center label to pods, block pods that break two guardrails, and expire old ConfigMaps.

---

## Ready for Assessment?

Test yourself with the [section knowledge check](./quiz.yaml) once you have finished the modules and the capstone.
