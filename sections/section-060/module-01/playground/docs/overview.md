# Overview: Apply Policies To Files With kyverno apply (Playground)

This is a **playground**, not a lab. It starts a cluster with Kyverno v1.13.2, installs the `kyverno` command on your machine, and waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it. Kyverno v1.13.2 runs in the namespace `kyverno`. No policy exists.
- The Kyverno CLI v1.13.2. Check it with `kyverno version`. If `kyverno` is not found in a new terminal, add `$HOME/.local/bin` to `PATH`.
- The directory `$HOME/kyverno-lab/m1`:

  | Path | What it is |
  | --- | --- |
  | `resources/pod-good.yaml` | Pod `web-good` with `team: platform`, image `nginx:1.27` |
  | `resources/pod-nolabel.yaml` | Pod `web-nolabel`, no `team` label |
  | `resources/pod-latest.yaml` | Pod `web-latest`, image `nginx:latest` |
  | `resources/pod-prod.yaml`, `pod-dev.yaml` | Pods with `env: prod` and `env: dev` |
  | `policies/`, `values/`, `out/` | Empty. Write your own files here |

- The namespace `lab` holds a Pod `legacy` with no `team` label. It exists before any policy.

## Helpers

Paste once in each new terminal. `chk` runs one policy on one resource and prints the exit code.

```sh
cd $HOME/kyverno-lab/m1
chk() { kyverno apply "policies/$1" --resource "resources/$2" "${@:3}"; echo "exit=$?"; }
```

Use it like this: `chk require-team-label.yaml pod-nolabel.yaml`, or add flags at the end: `chk disallow-latest-tag.yaml pod-latest.yaml --audit-warn`.

## Practice tasks

- Write a `require-team-label` policy with `validationFailureAction: Enforce`. Run `chk` on all five resources and predict each exit code first.
- Change the policy to `Audit`. Run it with and without `--audit-warn`, and compare the exit code and the summary line.
- Remove `namespaces: [lab]` from the match, or change it to `prod`. Predict the result for `web-nolabel`, then run it. Does the CLI skip the resource or fail it?
- Write a policy with the variable `{{ allowedEnv }}` and run it first without a value (read the error), then with `--set allowedEnv=prod`, then with a `Values` file passed with `--values-file`.
- Write a mutate policy and save the result with `-o out/patched.yaml`. Compare the file with `resources/pod-good.yaml`.
- Run a policy with `--cluster` and find `legacy`. Then `kubectl apply` the policy and compare what the live webhook does with the CLI result.
