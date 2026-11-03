# Part 1 - The kyverno-test.yaml format

## Three lists

A test file is a Kubernetes-style object of kind `Test` in the API group `cli.kyverno.io/v1alpha1`. It has three lists that matter:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: require-limits
policies:
  - ../../policies/require-limits.yaml
resources:
  - ../../resources/pod-with-limits.yaml
  - ../../resources/pod-no-limits.yaml
results:
  - policy: require-limits
    rule: check-limits
    resources:
      - web-ok
    kind: Pod
    result: pass
  - policy: require-limits
    rule: check-limits
    resources:
      - web-nolimits
    kind: Pod
    result: fail
```

`policies` lists the policy files to load. `resources` lists the resource files to evaluate. Both hold paths, and the paths are relative to the directory of the test file. `results` is the list of expectations. The CLI runs every policy on every resource, collects the real result of every rule, and then looks up each real result in your list. A test passes when each expectation matches the real result.

## The fields of one result

| Field | Meaning |
| --- | --- |
| `policy` | The `metadata.name` of the policy |
| `rule` | The `name` of the rule inside the policy |
| `resources` | A list of `metadata.name` values of the resources the expectation covers. Older files use the single field `resource` |
| `kind` | The kind of those resources, for example `Pod` |
| `namespace` | The namespace of the resources. Add it when the resource files set `metadata.namespace` |
| `result` | The expected result: `pass`, `fail` or `skip` (a warning is also possible for rules that warn) |
| `patchedResources` | For a mutate rule: a path to a file with the expected resource after mutation |
| `generatedResource` | For a generate rule: a path to a file with the expected generated resource |

Notice that `resources` in a result holds names, not paths. The path goes in the top-level `resources` list; the name goes in the result. A name that matches no loaded resource makes the CLI report that the result was not found, and the test fails. Policy and rule names are exact: a typo in `rule` looks like a rule that did not run.

> [!TIP]
> **Try it - break one name**
>
> Write the file above in `tests/limits/` and run `kyverno test tests/limits`. It succeeds. Now change `rule: check-limits` to `rule: check-limit` and run it again. The test fails, because no real result matches the expectation. Fix it again.

## What pass, fail and skip mean

The expected `result` describes what the policy does to the resource, not whether the test is good:

- `pass`: the rule applied to the resource and the resource satisfied it.
- `fail`: the rule applied and the resource violated it. You write `fail` for the negative sample, and the test succeeds when the policy really fails it.
- `skip`: the rule did not apply, for example because the `match` block does not select the resource or a precondition is false.

A test suite needs both kinds. A suite of only `pass` expectations passes for a policy that never fails anything. Always add a `fail` sample for every validate rule, and a `skip` sample when the match block has conditions you care about.

## Testing a mutate rule

A mutate rule changes the resource, so the expectation is the changed resource. You write it in a file and point to it with `patchedResources`:

```yaml
results:
  - policy: add-managed-by-label
    rule: add-label
    resources:
      - worker
    kind: Pod
    patchedResources: patched.yaml
    result: pass
```

The file `patched.yaml` holds the whole expected object: the original Pod with the extra label `managed-by: kyverno`. The CLI mutates the input resource in memory and compares the result with the file. The easiest way to create the file is to run `kyverno apply` with `-o`, read the output carefully, and check that it is what you expect. Do not copy the output without reading it: a wrong expected file locks the wrong behaviour into the test.

## How the runner pairs expectations with real results

The CLI does not run one policy against one resource for each line in `results`. It first runs every loaded policy on every loaded resource, in the same way as `kyverno apply`, and collects a real result for each combination of policy, rule and resource. Then it takes each expectation and looks up the real result with the same policy, rule, resource name and kind. If it finds one, it compares the `result` values. If it finds none, it reports the expectation as not found and the test fails.

This has two consequences. A real result that no expectation names is not an error: the test passes even if a rule produced a result you never wrote down. That is why `--detailed-results` is useful, because it shows those unlisted results. And a name in `results` that belongs to no loaded resource can never pass.

A policy in a namespace is named `<namespace>/<policy-name>` in the `policy` field. A cluster policy uses its plain name. Policies of the kind `ClusterPolicy` are the common case, so most files use the plain name.

The values for `result` come from the engine. `pass` and `fail` are the outcomes of a rule that ran. `skip` means the rule did not apply. `warn` appears when a failing resource is covered by a policy that carries the annotation `policies.kyverno.io/scored: "false"`. A failure of such a policy is reported as a warning, because the policy is not scored.

## Other fields of the test file

The `variables` field names a `Values` file, as for `kyverno apply`. The `userinfo` field names a `UserInfo` file, so you can test a rule that depends on who calls. Both files use the API group `cli.kyverno.io/v1alpha1`. To use another file name than `kyverno-test.yaml`, pass `-f <name>` to `kyverno test`. To run a subset of the expectations, use `--test-case-selector` with a string such as `"policy=require-limits, rule=check-limits, resource=web-ok"`.

## Variables in tests

A policy that needs variable values gets them from a values file, as with `kyverno apply`. In a test file, the `variables` field names the file. Use it for a policy that reads `request.operation`, namespace labels or other values that a resource file does not carry. Keep the values file next to the test file.

> [!TIP]
> **Try it - a mutate test**
>
> Write `tests/labels/kyverno-test.yaml` and `tests/labels/patched.yaml`, and run `kyverno test tests/labels`. Then delete the `managed-by` line from `patched.yaml` and run it again. The test fails because the policy output no longer equals the expectation.
