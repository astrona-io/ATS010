# Part 3 - Detailed results and kyverno jp

## The default table and --detailed-results

By default `kyverno test` prints a table with one row for each expectation in your `results` list. Each row shows the policy, the rule, the resource and whether the expectation was met. That is enough when everything passes.

`--detailed-results` adds the real results of every rule on every resource, not only the ones that you listed. Use it when a test fails and you need to see what the policy actually did.

```sh
kyverno test tests/limits --detailed-results
```

Read the output as three questions:

1. Is the row for my expectation present? If it is missing, the `policy`, `rule`, resource name or `kind` in the result does not match a real result. Check spelling and the namespace.
2. Is the real result what I expected? If the table shows `fail` for `web-ok`, the policy or the sample is wrong, not the test runner.
3. Are there real results that I never listed? Rows for resources that you forgot show rules that run but are not tested. Add expectations for them.

For a mutate test, a failure usually means that the expected file differs from the real patched resource. Run `kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-unlabelled.yaml -o /tmp/real.yaml` and compare `/tmp/real.yaml` with `patched.yaml` using `diff`.

## Common causes of a failing test

| Symptom | Likely cause |
| --- | --- |
| The expectation is reported as not found | Wrong `rule` name, wrong resource name, missing `namespace`, or a typo in `kind` |
| Expected `pass`, real `skip` | The `match` block does not select the resource. The sample lacks the namespace, label or kind that the rule needs |
| Expected `fail`, real `pass` | The sample is not really bad, or the pattern is too loose |
| Mutate test fails | The expected file has a different label order or missing fields, or the policy output changed |
| A test suddenly fails in CI only | A different CLI version than on your machine, or a path that depends on the current directory |

## kyverno jp: try a JMESPath expression

Many policies use JMESPath expressions in `{{ }}` variables, for example `{{ request.object.spec.containers[*].image }}`. JMESPath is a query language for JSON. A mistake in it is easy to make and hard to see in a policy. The CLI has a subcommand to try an expression on a file before you write it into a policy: `kyverno jp`.

```sh
kyverno jp query -i resources/pod-with-limits.yaml 'spec.containers[*].image'
```

`kyverno jp query` reads a JSON or YAML input file with `-i` and evaluates the expression on it. The result is printed as JSON, so you can see the exact shape that your policy will get. Two companions are useful: `kyverno jp function` lists the JMESPath functions that Kyverno adds to the standard set, and `kyverno jp parse` shows how an expression is parsed. Run `kyverno jp --help` to see what your version offers.

> [!TIP]
> **Try it - find the right expression**
>
> Write a small JSON file with a list of containers, and use `kyverno jp query` to extract the list of image names, then the number of containers (`length(spec.containers)`). When the result is what you need, put the same expression in a policy variable. Remember that in a live admission request, the object is under `request.object`, so in a policy you write `request.object.spec.containers`, while in `kyverno jp query` the file itself is the root.

## A workflow for a new policy

1. Write the policy. Use `kyverno jp query` for any non-trivial variable.
2. Write one good and one bad sample resource.
3. Run `kyverno apply` on them and read the counters and the exit code.
4. Write `kyverno-test.yaml` with the results that you just verified by eye, and run `kyverno test --detailed-results`.
5. Add the test to the CI script and open the pull request.
6. After the merge, apply the policy to the cluster, first with `Audit` if it is new, and check with a server-side dry run.

Each step catches a different kind of mistake, and only the last two touch the cluster.
