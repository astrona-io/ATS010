# Summary

`kyverno apply` evaluates policy files against resource files with the Kyverno engine and returns an exit code, so a policy can be proven before it reaches a cluster.

## What you learned

Policies are positional arguments (files or a directory) and resources come from `--resource` (`-r`). The CLI evaluates the `match` block, so a resource without the namespace that the rule matches is skipped, not passed. The summary line counts `pass`, `fail`, `warn`, `error` and `skip`. A failure of an `Enforce` policy makes the exit code non-zero. A failure of an `Audit` policy does too, unless you set `--audit-warn`, which counts it as a warning.

A file has no admission request, so the CLI needs values for variables. `-s`/`--set` sets simple values such as `request.operation`, and `--values-file` reads a `Values` file (`cli.kyverno.io/v1alpha1`) with values per policy rule and per resource. A mutate rule writes the patched resource with `-o` and never edits the input file. `--cluster` reads live resources instead of files and finds objects that exist before the policy. `--policy-report` prints a policy report in the `wgpolicyk8s.io/v1alpha2` format. The key facts to remember are these:

- Read the `skip` and `error` counters; only `pass` and `fail` prove a rule result.
- `Audit` fails the CLI run unless `--audit-warn` is set.
- A CLI result can differ from the live result because of defaults, user info, namespace labels, exceptions and the Kyverno version.
- Use the same CLI version as the Kyverno controllers, and finish with a cluster check.

<!-- astrona:playground:destroy -->
