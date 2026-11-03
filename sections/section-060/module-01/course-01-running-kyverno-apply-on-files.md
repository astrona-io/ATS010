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

## What the CLI does for each resource

The CLI runs the same steps as the admission controller, in the same order, but on the files you give it. For every resource it first loads the policies and checks them. Then, for every rule, it tests `match` and `exclude`. If the rule is selected, it evaluates the `preconditions`. Only then does it run the rule itself. A rule that stops at the match step or at the preconditions counts as `skip`. A rule that runs and succeeds counts as `pass`. A rule that runs and finds a violation counts as `fail`, or as `warn` for an Audit policy with `--audit-warn`.

Three details of this loop matter in practice. First, a namespaced `Policy` (not a `ClusterPolicy`) applies only to resources whose `metadata.namespace` equals the namespace of the policy. A file without that namespace is skipped. Second, for a policy that matches `Pod`, Kyverno generates extra rules for Pod controllers such as `Deployment`. Their names start with `autogen-`. The CLI evaluates them too, so a Deployment manifest is checked against a Pod rule without extra work. Third, the CLI reads the resources only from the files you name. It does not add defaults that the API server would add.

You can also pipe a manifest into the command. The value `-` after `--resource` makes the CLI read the resource from standard input. This is useful with output from `kubectl`:

```sh
kubectl -n lab get pod legacy -o yaml | kyverno apply policies/require-team-label.yaml --resource -
```

The manifest that `kubectl get -o yaml` returns is the live object, with the fields that the API server added. It is a better test input than a hand-written file when you want to know how a policy sees a real Pod.

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

Use it in a CI job that checks policies you have not yet moved to `Enforce`. The job shows the findings and does not stop the pipeline. `Enforce` policies still fail the job. This is the CLI version of the Audit-then-Enforce rollout.

> [!TIP]
> **Try it - flip the action**
>
> Change `disallow-latest-tag` from `Audit` to `Enforce` and run the same two commands. The first still fails. The second now also fails, because `--audit-warn` only softens `Audit` policies.

## Exit codes in a script

A shell script reads the exit code of the last command. In a script with `set -e`, a non-zero exit from `kyverno apply` ends the script at that line. If you want to run several policy checks and report all of them, store the code instead:

```sh
rc=0
for r in resources/*.yaml; do
  kyverno apply policies/ --resource "$r" || rc=1
done
exit "$rc"
```

The loop runs the policies on each file and remembers that at least one run failed. The final line returns one code for the whole job. Note that the resources in `resources/` include deliberately bad samples such as `pod-nolabel.yaml`, so this exact loop is only useful on a directory that holds files that must all pass.

## Reading failures

A failure block ends with the policy message and, for a `pattern`, the path of the field that did not match. Two habits save time. First, run one policy and one resource at a time while you write a rule, so each message has one cause. Second, when a result surprises you, check the counters again: `skip` means the match block did not select the resource, `error` means the policy or a variable could not be evaluated, and neither is a rule failure.

When a directory of policies is the argument, the CLI loads every policy file in it. A file that is not a Kyverno policy, or a policy with a schema mistake, produces an error and a non-zero exit. That makes `kyverno apply policies/` a cheap lint step for a policies repository.
