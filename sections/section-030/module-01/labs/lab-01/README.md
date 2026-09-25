# failurePolicy & Timeout Tuning Sandbox

Welcome to the Module 1 targeted practice sandbox. In this lab, you will author two `ClusterPolicy` resources with opposite `failurePolicy` settings, prove they both enforce identically while Kyverno is healthy, and (optionally) observe how they diverge when Kyverno's admission controller is unreachable.

## Launching the Lab
Run the following command in your terminal to boot the kind Kubernetes cluster:
```bash
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-030/module-01/labs/lab-01
```
