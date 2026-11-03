---
estimated_duration: 40m
---

# Capstone: Ship A Policy Through apply, test And CI

> **UNTESTED - built from static checks only; not yet booted.**

Capstone for section 060. You write one policy, prove it with `kyverno apply`, lock the result in with a `kyverno test` file and a CI script, scan the existing cluster with `--cluster`, and apply the proven policy. The validation scripts run the `kyverno` CLI on your files, also on temporary copies that break the policy. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-060/capstone/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-060/capstone/labs/lab-01
astrona destroy ats-010-lab-018
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policy-and-exit-codes.sh` | `restrict-registry` is an Enforce policy; `api` passes, `web` fails |
| `validate-test-file.sh` | `tests/kyverno-test.yaml` has pass and fail results and `kyverno test` succeeds |
| `validate-regression-caught.sh` | `kyverno test` fails when the policy changes |
| `validate-audit-warn.sh` | In Audit mode `web` fails, and `--audit-warn` makes the exit code 0 |
| `validate-ci-script.sh` | `ci/run.sh` is executable, uses `set -e`, runs `kyverno test` from any directory |
| `validate-cluster-scan.sh` | `kyverno apply --cluster` names `legacy-external` (depends on the CLI output naming the resource) |
| `validate-policy-live.sh` | The policy is Ready in the cluster, rejects the docker.io Pod, admits the ghcr.io/acme Pod |
