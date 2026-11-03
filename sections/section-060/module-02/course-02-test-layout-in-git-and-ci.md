# Part 2 - Test layout in git and CI

## One repository for policies, samples and tests

Tests are code, so they live in git next to the policies that they check. A reviewer then sees a policy change and its test change in the same pull request. A layout that works for a small policy repository looks like this:

```text
policy-repo/
  policies/
    require-limits.yaml
    add-managed-by-label.yaml
  resources/
    pod-with-limits.yaml
    pod-no-limits.yaml
    pod-unlabelled.yaml
  tests/
    limits/
      kyverno-test.yaml
    labels/
      kyverno-test.yaml
      patched.yaml
  ci/
    run-policy-tests.sh
```

The sample resources are in one place because several tests can reuse them. Each test directory holds one `kyverno-test.yaml` for one policy (or one closely related group of policies) and the files that only that test needs, such as the expected mutated resource. Paths in the test file reach `policies/` and `resources/` with `../../`.

Name the sample resources after what they prove: `pod-no-limits.yaml` is better than `pod2.yaml`. When a test fails in CI, the resource name in the failure line is often the whole diagnosis.

## Running tests

`kyverno test` takes a path. If the path is a directory, the CLI searches it, including its subdirectories, for files named `kyverno-test.yaml` and runs each one. If the path holds a single test directory, it runs that test.

```sh
kyverno test tests          # every test under tests/
kyverno test tests/limits   # one test directory
```

It prints a table of results, one row per expectation, and finishes with a non-zero exit code if at least one expectation differs from the real result or cannot be found. That exit code is all a CI system needs.

## The CI job

A pipeline job has three steps: get the CLI, run the tests, and fail on a non-zero exit code. The CLI is one binary. Download the release tarball of the exact version (the lab bootstrap does this for v1.13.2), put it on `PATH`, and check it with `kyverno version`. Pin the version in the job. A floating "latest" CLI can change the format or the result of a rule between two runs of the same commit.

```sh
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
kyverno test tests
```

Three details make this script safe. `set -euo pipefail` stops the script on the first error, so the job result is the result of `kyverno test`. `cd "$(dirname "$0")/.."` makes the script work from any current directory, because CI systems start in different places. The last command is the test, so its exit code becomes the exit code of the script. A GitHub Actions, GitLab CI or Jenkins job then only runs this script.

> [!TIP]
> **Try it - prove the gate works**
>
> Run `ci/run-policy-tests.sh` and note that the exit code is 0. In a scratch copy of the directory, change the policy so that it no longer matches the expectation (for example, change `"?*"` to a value that no container sets), run the script again, and check that the exit code is non-zero. A CI test that you have never seen fail is a test that you do not know works. The lab grades exactly this check.

## Where kyverno test reads from

The path argument can also be a Git repository URL. In that case the CLI clones the repository and searches it for test files. The flag `-b` (long form `--git-branch`) selects the branch and defaults to `main`. For a CI job this is rarely needed, because the job already has the repository checked out. The local path is the common case.

Paths inside a test file are relative to the directory of that file, not to the directory where you run the command. That rule is why `../../policies/require-limits.yaml` works from any current directory. If you move a test directory one level deeper, every `../../` must change to `../../../`. A broken path shows up as an error that the policy or resource file cannot be read.

## An example job

The job needs two things from the environment: the pinned CLI and the repository. The commands below install CLI v1.13.2 on a Linux x86-64 runner. The name of the release file is `kyverno-cli_v1.13.2_linux_x86_64.tar.gz`, and the archive holds one binary named `kyverno`:

```sh
curl -fsSL -o /tmp/kyverno-cli.tar.gz \
  https://github.com/kyverno/kyverno/releases/download/v1.13.2/kyverno-cli_v1.13.2_linux_x86_64.tar.gz
tar -xzf /tmp/kyverno-cli.tar.gz -C /tmp kyverno
install -m 0755 /tmp/kyverno /usr/local/bin/kyverno
kyverno version
ci/run-policy-tests.sh
```

On a Mac or an ARM machine the file name changes: the operating system is `darwin` or `linux`, and the architecture is `x86_64` or `arm64`. The lab bootstrap detects both with `uname`. The release also publishes a checksums file. A strict pipeline downloads it and checks the archive before it installs the binary.

## What to test

For each policy, write at least:

- one resource that must pass (a compliant sample) and one that must fail (a violation sample), for every validate rule;
- one resource that the rule must skip, if the match or the preconditions are specific (for example, a Pod in another namespace);
- the expected output file, for every mutate rule;
- a test for every edge case that you fixed once: when a bug report becomes a sample and an expectation, the bug cannot return unseen.

Keep the samples small. A Pod with ten fields is easier to reason about than a copy of a production manifest.

## Tests are not the cluster

A passing `kyverno test` says that the policy engine gives the expected result for the file samples. It does not prove that the policy is applied to the cluster, that the webhook sees the resource, or that an exception does not exempt it. The differences are the same as for `kyverno apply`: API server defaults, request data such as `request.userInfo`, namespace labels, exceptions and the webhook configuration. Keep a deployment step after the tests, and a cluster check such as `kubectl apply --dry-run=server` for a known bad resource. The lab ends with such a check.
