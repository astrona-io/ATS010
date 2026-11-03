# Section 060: Kyverno CLI: apply & test

A policy that you first meet in a live cluster is tested too late. The Kyverno command-line tool (`kyverno`) runs the same policy engine on files, so you can prove a policy on your machine and in CI before it reaches the admission webhook. This section teaches the two commands that do the work: `kyverno apply`, which evaluates policies against resources and sets an exit code, and `kyverno test`, which stores the expected results in git and fails a build when they change.

---

## What You Will Master

By completing this section, you will acquire two core Applying Policies competencies:
*   **Applying policies offline:** Running `kyverno apply` with policy and resource files, reading the pass, fail, warn, error and skip counters and the exit code, using `--audit-warn`, supplying variables with `-s`/`--set` and `--values-file`, saving mutated resources with `-o`, scanning a live cluster with `--cluster`, producing a report with `--policy-report`, and knowing where a CLI result can differ from the live cluster.
*   **Testing policies as code:** Writing `kyverno-test.yaml` files with `policies`, `resources` and `results` (including `patchedResources` for mutate rules), laying tests out in git, running `kyverno test` in a CI script, reading `--detailed-results`, and trying JMESPath expressions with `kyverno jp`.

---

## The Learning & Lab Path

Each module starts a playground (a free sandbox with Kyverno v1.13.2 in a `kind` cluster and the Kyverno CLI v1.13.2 installed on your machine) and ends with a graded lab. The labs run `kyverno apply` and `kyverno test` on the files that you write in `$HOME/kyverno-lab`.

> **UNTESTED - built from static checks only; not yet booted.** The labs in this section have not been run end to end.

### 1. Kyverno CLI: apply
*   **Module Reader:** **[Module 1: Kyverno CLI: apply](./module-01/course.md)**
    1. [Running kyverno apply on files](./module-01/course-01-running-kyverno-apply-on-files.md)
    2. [Variables and mutate output](./module-01/course-02-variables-and-mutate-output.md)
    3. [Cluster mode, reports and where the CLI differs](./module-01/course-03-cluster-mode-reports-and-differences.md)
    4. [Summary](./module-01/course-04-summary.md)
*   **Playground:** `sections/section-060/module-01/playground`
*   **Practice Lab Sandbox:** **`sections/section-060/module-01/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-01/labs/lab-01
    ```
*   **Hands-on Objective:** Write four policies, prove them with `kyverno apply` (exit codes, `--audit-warn`, a values file, `-o`), scan the cluster with `--cluster`, and apply the proven policy.

### 2. Kyverno CLI: test
*   **Module Reader:** **[Module 2: Kyverno CLI: test](./module-02/course.md)**
    1. [The kyverno-test.yaml format](./module-02/course-01-the-kyverno-test-yaml-format.md)
    2. [Test layout in git and CI](./module-02/course-02-test-layout-in-git-and-ci.md)
    3. [Detailed results and kyverno jp](./module-02/course-03-detailed-results-and-jp.md)
    4. [Summary](./module-02/course-04-summary.md)
*   **Playground:** `sections/section-060/module-02/playground`
*   **Practice Lab Sandbox:** **`sections/section-060/module-02/labs/lab-01`**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-02/labs/lab-01
    ```
*   **Hands-on Objective:** Write a validate test and a mutate test, a CI script that runs `kyverno test`, prove that a broken policy fails the tests, and apply the tested policy.

### 3. Section Capstone Challenge
*   **Comprehensive Challenge:** **`sections/section-060/capstone/labs/lab-01` (Ship a policy through apply, test and CI)**
*   **Lab Run Command:**
    ```bash
    astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Write a registry restriction policy, prove it with `kyverno apply`, lock it in with `kyverno test` and a CI script, scan the cluster, and apply it live.

### 4. Knowledge Check
*   **Quiz:** **[Section 060 quiz](./quiz.yaml)** - ten scenario questions about both modules.
