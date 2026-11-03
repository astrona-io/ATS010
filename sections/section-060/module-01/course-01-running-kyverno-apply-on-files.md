# Part 1 - Running kyverno apply on files

## One command, two kinds of input

`kyverno apply` needs policies and resources. The policy files are positional arguments: you list one or more files, or a directory that holds policy files. The resources come from the `--resource` flag (short form `-r`), which you can repeat. The command loads both sets, matches every rule against every resource, runs the rules that match, and prints the result.

```sh
kyverno apply policies/require-team-label.yaml --resource resources/pod-good.yaml
kyverno apply policies/ --resource resources/pod-good.yaml --resource resources/pod-nolabel.yaml
```

The output has a first line that says how many policy rules were applied to how many resources. Each failure follows as a block that names the policy, the rule and the resource, and shows the validation message. The last line is a summary with five counters: `pass`, `fail`, `warn`, `error` and `skip`. Read the counters before you read anything else. A run with `fail: 0` and `skip: 1` did not prove that the resource is compliant: the policy never applied to it.

> [!TIP]
> **Try it - one passing and one failing resource**
>
> In `$HOME/kyverno-lab/m1` write `policies/require-team-label.yaml` (the policy from the lab task), then run:
>
> ```sh
> kyverno apply policies/require-team-label.yaml --resource resources/pod-good.yaml; echo "exit=$?"
> kyverno apply policies/require-team-label.yaml --resource resources/pod-nolabel.yaml; echo "exit=$?"
> ```
>
> The first run prints no failure and `exit=0`. The second names `web-nolabel` as failed and prints a non-zero exit code.

## The CLI uses the match block, so resource files need a namespace

The CLI does not run every rule on every file. It evaluates the `match` and `exclude` blocks of each rule first. A rule that matches `kinds: [Pod]` and `namespaces: [lab]` applies only to a Pod whose `metadata.namespace` is `lab`. A manifest without a `namespace` field has no namespace in the file, so the rule does not match and the CLI counts the resource as skipped.

This is the most common reason for a "passing" run that proves nothing. When you write a policy with `namespaces` or `namespaceSelector`, put the namespace in the resource file. The lab manifests all carry `namespace: lab` for this reason.

## What the exit code means

The exit code is the contract between the CLI and a script or a CI job. The rules in Kyverno 1.13 are these:

| Situation | Exit code |
| --- | --- |
| Every resource passes every matching rule | 0 |
| A resource fails a rule of an `Enforce` policy | non-zero |
| A resource fails a rule of an `Audit` policy | non-zero, unless you pass `--audit-warn` |
| A policy or a resource file cannot be loaded or evaluated (the `error` counter) | non-zero |
| A rule does not match (`skip`) | no effect on the exit code |

The CLI does not use `validationFailureAction` to decide whether to run a rule, because in a file-based run nothing is blocked. The field only decides whether a failure is a failure or a warning. This surprises many learners: an `Audit` policy makes `kyverno apply` fail, while the same policy in a cluster only writes a report.

## --audit-warn

`--audit-warn` changes how the CLI counts the failures of policies in `Audit` mode. Without it they are failures and the exit code is non-zero. With it they are warnings: the `warn` counter increases, the `fail` counter does not, and the exit code stays 0 when nothing else fails.

```sh
kyverno apply policies/disallow-latest-tag.yaml --resource resources/pod-latest.yaml; echo "exit=$?"
kyverno apply policies/disallow-latest-tag.yaml --resource resources/pod-latest.yaml --audit-warn; echo "exit=$?"
```

Use it in a CI job that checks policies you have not yet moved to `Enforce`. The job shows the findings and does not stop the pipeline. `Enforce` policies still fail the job. This is the CLI version of the Audit-then-Enforce rollout from section 010.

> [!TIP]
> **Try it - flip the action**
>
> Change `disallow-latest-tag` from `Audit` to `Enforce` and run the same two commands. The first still fails. The second now also fails, because `--audit-warn` only softens `Audit` policies.

## Reading failures

A failure block ends with the policy message and, for a `pattern`, the path of the field that did not match. Two habits save time. First, run one policy and one resource at a time while you write a rule, so each message has one cause. Second, when a result surprises you, check the counters again: `skip` means the match block did not select the resource, `error` means the policy or a variable could not be evaluated, and neither is a rule failure.

When a directory of policies is the argument, the CLI loads every policy file in it. A file that is not a Kyverno policy, or a policy with a schema mistake, produces an error and a non-zero exit. That makes `kyverno apply policies/` a cheap lint step for a policies repository.
