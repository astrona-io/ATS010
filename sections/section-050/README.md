# Section 050: Policy Reports & Results

A policy that runs is only useful if you can read what it found. This section is about the reports Kyverno writes: how to read a `PolicyReport` and a `ClusterPolicyReport`, where each result comes from, how results age, and how to use them as the evidence for flipping an `Audit` policy to `Enforce`.

You will start with the shape of the report objects and the queries that turn many small reports into one answer, then follow the pipeline behind them: admission-time results, background scans, ephemeral reports, what happens when a resource or a policy goes away, and what `skip` means.

---

## What You Will Master

By completing this section, you will acquire two core Applying Policies competencies:
*   **Reading Reports:** Telling `PolicyReport` from `ClusterPolicyReport`, reading `summary` and `results` (`policy`, `rule`, `result`, `message`, `scope`), knowing the five result values, and querying them with `kubectl` and `jq` without depending on one Kyverno version's layout.
*   **Understanding Results Over Time:** Knowing that results come from admission and from background scans, that the scan interval defaults to one hour, that results disappear with their resource or policy, that `Enforce` leaves no trace of blocked requests, and how to use clean reports as a rollout gate.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each with a playground and a graded lab on a kind Kubernetes cluster running Kyverno v1.13.2. The section concludes with a Capstone Integration Challenge. All labs in this section are UNTESTED - built from static checks only; not yet booted.

### 1. Reading PolicyReport and ClusterPolicyReport
*   **Module Reader:** **[Module 1: Reading PolicyReport and ClusterPolicyReport](./module-01/course.md)**
    1. [Anatomy of a Report](./module-01/course-01-anatomy-of-a-report.md)
    2. [Querying Reports with kubectl and jq](./module-01/course-02-querying-reports.md)
    3. [Summary](./module-01/course-03-summary.md)
*   **Playground:** **`sections/section-050/module-01/playground`**
*   **Practice Lab Sandbox:** **`sections/section-050/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Read the reports of two `Audit` policies, find the failing ConfigMaps and Namespaces, count the results, and record the findings without changing anything.

### 2. Where Results Come From and How They Age
*   **Module Reader:** **[Module 2: Where Results Come From and How They Age](./module-02/course.md)**
    1. [Two Sources: Admission and Background Scan](./module-02/course-01-admission-and-background-scan.md)
    2. [Lifecycle: Deleted Resources, Deleted Policies and Skipped Results](./module-02/course-02-lifecycle-and-skipped-results.md)
    3. [Reports as a Rollout Gate](./module-02/course-03-reports-as-a-rollout-gate.md)
    4. [Summary](./module-02/course-04-summary.md)
*   **Playground:** **`sections/section-050/module-02/playground`**
*   **Practice Lab Sandbox:** **`sections/section-050/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Use the reports as a gate: fix or delete the violators, wait until the reports are clean, flip the policy to `Enforce` and prove a rejection and an admission.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-050/capstone/labs/lab-01` (Policy Reports & Results Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Read a `PolicyReport` per namespace and a `ClusterPolicyReport`, remediate every violator, wait for both report kinds to turn clean, and move two policies to `Enforce` with proof.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 050 Knowledge Check Quiz](./quiz.yaml)**
