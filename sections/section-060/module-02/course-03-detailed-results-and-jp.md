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

## A failing mutate test, step by step

Suppose `kyverno test tests/labels` reports that the mutate expectation failed. Follow the same three steps each time. First, run `kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-unlabelled.yaml -o /tmp/real.yaml`. This writes what the policy really produces. Second, run `diff /tmp/real.yaml tests/labels/patched.yaml`. Every line in the diff is a difference between the real result and your expectation. Third, decide which side is wrong. If the policy is right, change `patched.yaml`. If the policy is wrong, fix the policy and leave the expectation alone.

Never change both at once to make the test green. The expected file records the behaviour that you decided is correct. A test that you edit to match whatever the policy does is only a copy of the policy.

## Common causes of a failing test

| Symptom | Likely cause |
| --- | --- |
| The expectation is reported as not found | Wrong `rule` name, wrong resource name, missing `namespace`, or a typo in `kind` |
| Expected `pass`, real `skip` | The `match` block does not select the resource. The sample lacks the namespace, label or kind that the rule needs |
| Expected `fail`, real `pass` | The sample is not really bad, or the pattern is too loose |
| Mutate test fails | The expected file has a different label order or missing fields, or the policy output changed |
| A test suddenly fails in CI only | A different CLI version than on your machine, or a path that depends on the current directory |

## Running only the test you are debugging

A directory with many tests prints many rows. When one expectation fails, run only that one with `--test-case-selector`. The value is a comma-separated list of `key=value` filters. The keys are `policy`, `rule` and `resource`:

```sh
kyverno test tests --test-case-selector "policy=require-limits, rule=check-limits, resource=web-nolimits" --detailed-results
```

This keeps the output short enough to read. When the selected expectation passes alone but the full run fails, another test in the suite is the cause. The selector is also a quick way to confirm that a new expectation is the one that fails, and not an older one.

A second habit helps with failures in a mutate test. The comparison is between the whole expected resource and the whole patched resource. A single extra field in `patched.yaml`, for example a `status` block copied from a live object, makes the test fail although the label is correct. Keep the expected file as small as the input file plus the change.

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

### Useful JMESPath forms

A few forms cover most policies. `spec.containers[*].image` returns the list of all image strings. `length(spec.containers)` returns the number of containers. `spec.containers[?name=='app'].image` filters the list by a condition: the value inside single quotes is a string. `metadata.labels.team || 'none'` returns a default when the label is missing. Kyverno adds functions such as `to_upper`, `contains` and `regex_match`. Run `kyverno jp function` to list them with their signatures. Try an expression with `kyverno jp query` on a real manifest first, then copy it into the policy.

## Why the JMESPath root differs

In a policy, a variable such as `{{ request.object.spec.containers[*].image }}` starts at `request`. Kyverno builds `request` from the admission request, and `request.object` is the resource. In `kyverno jp query` there is no admission request. The input file is the root of the expression, so the same query is `spec.containers[*].image`. When you copy an expression from the terminal into a policy, add the prefix `request.object.`. When you copy it back, remove the prefix. Forgetting this is the most common reason why an expression works in `kyverno jp` and returns an empty value in a policy.

An empty result is not an error in JMESPath. A path that does not exist returns `null`. A rule that compares `null` with a string fails or errors, depending on the operator. Test the missing case too: run the expression on a resource that lacks the field and look at the result.

## A workflow for a new policy

1. Write the policy. Use `kyverno jp query` for any non-trivial variable.
2. Write one good and one bad sample resource.
3. Run `kyverno apply` on them and read the counters and the exit code.
4. Write `kyverno-test.yaml` with the results that you just verified by eye, and run `kyverno test --detailed-results`.
5. Add the test to the CI script and open the pull request.
6. After the merge, apply the policy to the cluster, first with `Audit` if it is new, and check with a server-side dry run.

Each step catches a different kind of mistake, and only the last two touch the cluster.

## Common pitfalls

- Copying `kyverno apply` output into `patched.yaml` without reading it. The test then confirms a mistake.
- Keeping only `pass` expectations, so a policy that never fails anything keeps the suite green.
- Using the root `request.object` in `kyverno jp query`. The input file is the root there.
- Reading a missing row in the table as a passing test. A missing row means that no real result matched the expectation, so the policy, rule, resource name or kind is wrong.
- Using a different CLI version in CI than on the laptop. Pin the version in both places.
