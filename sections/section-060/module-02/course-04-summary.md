# Summary

`kyverno test` turns the results that you checked by hand into expectations that a computer checks on every commit.

## What you learned

A `kyverno-test.yaml` has the kind `Test` (`cli.kyverno.io/v1alpha1`) and three lists. `policies` and `resources` hold file paths relative to the test file. `results` holds expectations with `policy`, `rule`, `resources` (resource names), `kind`, an optional `namespace`, and `result` set to `pass`, `fail` or `skip`. A mutate test adds `patchedResources` with the expected resource. A suite needs good and bad samples for every rule, otherwise it can pass for a policy that does nothing.

Tests live in git with the policies and the sample resources. `kyverno test <directory>` finds every `kyverno-test.yaml` below it and exits non-zero when an expectation differs, so a three-line CI script that uses `set -euo pipefail` is a policy gate. `--detailed-results` shows the real result of every rule so that you can see why an expectation was not met. `kyverno jp query` evaluates a JMESPath expression on a file, so you can check a variable before you use it in a policy. The key facts to remember are these:

- Paths in a test file are relative to the test file; names in `results` are `metadata.name` values.
- Always test a `fail` sample, and prove that the suite fails when the policy is broken.
- Pin the CLI version in CI to the Kyverno version in the cluster.
- A passing test is not a cluster check: finish with a deployment and a server-side dry run.

<!-- astrona:playground:destroy -->
