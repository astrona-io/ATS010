# Enforce-Mode Resource Limits Policy Sandbox

Welcome to the Module 1 targeted practice sandbox. In this lab, you will apply a policy in `Audit` mode, watch it admit-and-report a violation, then flip it to `Enforce` and prove the change actually blocks new violators.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-01/labs/lab-01
```
