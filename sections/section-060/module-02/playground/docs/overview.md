# Overview: Test Policies With kyverno test (Playground)

This is a **playground**, not a lab. It starts a cluster with Kyverno v1.13.2, installs the `kyverno` command on your machine, and waits. There is no task, no `astrona submit` and no pass or fail. Write tests, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35 with Kyverno v1.13.2 in the namespace `kyverno`. No policy exists in the cluster.
- The Kyverno CLI v1.13.2. Check it with `kyverno version`. If `kyverno` is not found in a new terminal, add `$HOME/.local/bin` to `PATH`.
- The directory `$HOME/kyverno-lab/m2`:

  | Path | What it is |
  | --- | --- |
  | `policies/require-limits.yaml` | Validate policy, rule `check-limits` (memory limit required) |
  | `policies/add-managed-by-label.yaml` | Mutate policy, rule `add-label` (adds `managed-by: kyverno`) |
  | `resources/pod-with-limits.yaml` | Pod `web-ok` |
  | `resources/pod-no-limits.yaml` | Pod `web-nolimits` |
  | `resources/pod-unlabelled.yaml` | Pod `worker` |
  | `tests/limits/`, `tests/labels/`, `ci/` | Empty. Write your tests here |

## Helpers

```sh
cd $HOME/kyverno-lab/m2
t() { kyverno test "${1:-tests}" --detailed-results; echo "exit=$?"; }
```

## Practice tasks

- Write `tests/limits/kyverno-test.yaml` with `pass` for `web-ok` and `fail` for `web-nolimits`. Run `t tests/limits`.
- Change the expected result of `web-nolimits` to `pass`. Read what `--detailed-results` prints and what the exit code is. Change it back.
- Write the mutate test with `patchedResources`. Remove the `managed-by` line from the expected file and read the failure.
- Run `t` on the whole `tests` directory. Which test files does the CLI find?
- Try `kyverno jp query` on a small JSON file you write. For example, `kyverno jp query -i data.json 'items[*].name'`. Use `kyverno jp --help` to see the other subcommands.
- Add a `variables` file to a test when a policy needs a value. Compare it with the `--values-file` flag of `kyverno apply`.
