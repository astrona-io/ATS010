# Section 010: Applying Policy in Cluster

Welcome to your first domain in Applying Policies. Writing a correct `ClusterPolicy` is only half the job — this section is about the other half: getting that policy actually live and behaving the way you intend against a real, already-running cluster.

You'll move from the mechanics of applying and inspecting a policy with `kubectl`, through the single field that decides whether a violation blocks or merely gets logged, into the mechanisms Kyverno gives you for reaching resources admission control alone can never see: background scans of what already exists, autogen rules that extend a Pod-scoped check to the controllers that actually spawn Pods, and PolicyExceptions for a scoped, auditable override.

---

## What You Will Master

By completing this section, you will acquire two core Applying Policies competencies:
*   **Applying & Inspecting Policies:** Getting a `ClusterPolicy`/`Policy` live with `kubectl apply`, confirming it's ready with `kubectl get`/`kubectl describe`, and understanding the difference between `validationFailureAction: Enforce` (blocks at admission) and `Audit` (admits and records), including staged rollout with `validationFailureActionOverrides`.
*   **Reaching Beyond Admission:** What `background: true` does and doesn't do, how autogen automatically extends a Pod-scoped rule to Deployment-owning controllers, and how to enable and use a `PolicyException` to carve out a scoped, auditable exemption without editing the policy itself.

---

## The Learning & Lab Path

This section is divided into two sequential modules, each paired with a dedicated graded lab on a kind Kubernetes cluster. The section concludes with a comprehensive Capstone Integration Challenge:

### 1. Getting a Policy Live: ClusterPolicy vs Policy & the Admission Path
*   **Module Reader:** **[Module 1: Getting a Policy Live](./module-01/course.md)**
    1. [Applying ClusterPolicy & Policy with kubectl](./module-01/course-01-applying-clusterpolicy-and-policy-with-kubectl.md)
    2. [Enforce vs Audit at Apply Time](./module-01/course-02-enforce-vs-audit-at-apply-time.md)
*   **Practice Lab Sandbox:** **`sections/section-010/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Apply a resource-limits policy in `Audit` mode, confirm a violation is admitted and reported, then flip it to `Enforce` and prove it now blocks new violators while admitting compliant Pods.

### 2. Applying Beyond Admission: Background Scans, Autogen & Exceptions
*   **Module Reader:** **[Module 2: Applying Beyond Admission](./module-02/course.md)**
    1. [Background Scanning Already-Existing Resources](./module-02/course-01-background-scanning-already-existing-resources.md)
    2. [Autogen for Pod Controllers & PolicyExceptions](./module-02/course-02-autogen-and-policyexceptions.md)
*   **Practice Lab Sandbox:** **`sections/section-010/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Apply a policy against a cluster with a pre-existing non-compliant Deployment, confirm autogen and background scanning both do their job, then enable and use a `PolicyException` to exempt that legacy workload.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-010/capstone/labs/lab-01` (Applying Policy in Cluster Integration)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Roll out Enforce in one namespace and Audit in another from two separate policies, confirm a legacy Deployment is reported but untouched, and use a PolicyException to admit a migration Job despite an otherwise-blocking rule.

---

## Ready for Assessment?

Test your theoretical knowledge and diagnostic reasoning before tackling the practical lab missions:

*   **[Take the Section 010 Knowledge Check Quiz](./quiz.md)**
