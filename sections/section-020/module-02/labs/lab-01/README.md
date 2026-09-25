# Identity-Based Resource Selection Sandbox

Welcome to the Module 2 targeted practice sandbox. In this lab, you will combine `objectSelector`, `operations`, and a `subjects`-based `exclude` block to build a rule that applies to exactly one label-selected slice of Pods, except for one trusted automation identity.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-020/module-02/labs/lab-01
```
