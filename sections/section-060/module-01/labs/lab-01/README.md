---
estimated_duration: 30m
---

# Lab: Prove Policies Offline With kyverno apply

> **UNTESTED - built from static checks only; not yet booted.**

Graded lab for Module 1. You write four policies in `$HOME/kyverno-lab/m1/policies`, run `kyverno apply` against the Pod manifests in `resources/`, and read the exit codes. The validation scripts run `kyverno apply` themselves on your files. The last check is on the cluster: the proven policy must be live. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-01/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-060/module-01/labs/lab-01
astrona destroy ats-010-lab-016
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policy-files.sh` | The four policy files exist with the required policy and rule names; Enforce and Audit actions are set |
| `validate-enforce-exit-codes.sh` | `kyverno apply` exits 0 for `web-good` and non-zero for `web-nolabel` |
| `validate-audit-warn.sh` | An Audit failure exits non-zero, and exits 0 with `--audit-warn` |
| `validate-variables-values-file.sh` | `--values-file` supplies `allowedEnv`; `web-prod` passes, `web-dev` fails |
| `validate-mutate-output.sh` | The mutate policy adds `managed-by: kyverno`; `out/patched.yaml` holds the result |
| `validate-cluster-scan.sh` | `kyverno apply --cluster` reports the existing Pod `legacy` (depends on the CLI output naming the resource) |
| `validate-policy-live.sh` | `require-team-label` is Ready in the cluster, rejects `web-nolabel` and admits `web-good` |
