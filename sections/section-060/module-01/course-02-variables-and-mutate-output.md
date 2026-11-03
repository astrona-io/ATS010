# Part 2 - Variables and mutate output

## Where variables come from

A Kyverno policy can contain `{{ }}` variables. In a live cluster, Kyverno fills most of them from the admission request: `request.object` is the resource, `request.operation` is `CREATE` or `UPDATE`, and `request.userInfo` is the caller. In `kyverno apply` there is no admission request. The CLI sets `request.object` from your resource file, and you must supply every other variable yourself. If a policy uses a variable that has no value, the CLI reports an error for that rule instead of guessing. The `error` counter goes up and the exit code is non-zero.

There are two ways to give values: the `-s` flag and a values file.

## -s / --set

`-s` (long form `--set`) sets simple variables on the command line, as `name=value` pairs separated by commas. It suits one or two values, for example the operation of the request:

```sh
kyverno apply policies/block-updates.yaml --resource resources/pod-good.yaml --set request.operation=UPDATE
```

The rule then sees `{{ request.operation }}` as `UPDATE`. This is how you test a rule that behaves differently on `CREATE` and `UPDATE`, because a file has no operation. Set the value you want to test and run the command once per operation.

## --values-file

For many values, or values that differ per policy or per resource, you write a values file and pass it with `--values-file`. In Kyverno 1.13 the file has the kind `Values` in the API group `cli.kyverno.io/v1alpha1`:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Values
policies:
  - name: require-env-label
    rules:
      - name: check-env
        values:
          allowedEnv: prod
    resources:
      - name: web-dev
        values:
          allowedEnv: dev
```

Read it from the top. Each item of `policies` names a policy. A `rules` item names a rule of that policy and sets `values` for it. A `resources` item names a resource (by `metadata.name`) and sets values only when that resource is evaluated. Values for a resource are the right place for facts that belong to one object, such as a different namespace label per Pod. The values file can also describe namespace labels in a `namespaceSelector` list, so that rules with a `namespaceSelector` in the match block can select your resource. If you are not sure about a field, run `kyverno apply --help` and read the documentation for the CLI version that you installed.

```sh
kyverno apply policies/require-env-label.yaml --resource resources/pod-prod.yaml --values-file values/values.yaml
```

> [!TIP]
> **Try it - supply and remove a value**
>
> Run the command above and note the exit code. Remove the `allowedEnv` line from the values file and run it again. The run now reports an error for the rule because the variable has no value. A policy that works in a cluster without values can still need values in the CLI, for example when it reads `request.userInfo` or a ConfigMap through a context entry.

## Global values and namespace labels

A values file has two more top-level fields that save repetition. `globalValues` holds values that apply to every policy and every resource in the run. A value in a `resources` item with the same name overrides the global value for that resource only. The field `namespaceSelector` lists namespaces with their labels:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Values
globalValues:
  request.operation: UPDATE
namespaceSelector:
  - name: lab
    labels:
      env: dev
```

A file holds no namespace labels, because labels belong to the `Namespace` object and not to the Pod. A rule with `namespaceSelector` in its `match` block needs them, so the CLI reads them from this list. Without an entry for the namespace of the resource, the rule does not match and the resource is skipped. The key `request.operation` in `globalValues` is the same variable that `--set request.operation=UPDATE` sets.

For a rule that reads `request.userInfo`, the CLI accepts a user-info file with `--userinfo` (short form `-u`). The file has the kind `UserInfo` in `cli.kyverno.io/v1alpha1`. It holds `clusterRoles` and a `userInfo` object with a `username`. This lets you test a rule that exempts a service account, as the live cluster would see the caller.

## Variables that need a cluster

Some variables need data that no file contains. A `context` entry that reads a `ConfigMap` or calls the Kubernetes API (`apiCall`) needs a cluster. In a file-based run, give the value in the values file instead, or run the command with `--cluster` (next part). Test rules that use `request.userInfo`, `request.roles` or `request.clusterRoles` by supplying those values too. The CLI can take a user-info file for this purpose; see `kyverno apply --help`.

## Mutate: getting the patched resource

A mutate rule changes a resource. With `kyverno apply` the resource file is never edited. The CLI computes the patched resource in memory and writes it out. Use `-o` (long form `--output`) with a file path to save it:

```sh
kyverno apply policies/add-managed-by-label.yaml --resource resources/pod-good.yaml -o out/patched.yaml
```

Without `-o` the CLI prints the result to the terminal. With `-o` you get a file that you can read, diff against the input, and use as the expected output of a test. When the resources argument names several files, give `-o` a directory.

```sh
diff resources/pod-good.yaml out/patched.yaml
```

The diff shows only the added `managed-by: kyverno` label. If it shows nothing, the rule did not match; check the `skip` counter.

> [!TIP]
> **Try it - mutate then validate**
>
> A policy set can contain both a mutate and a validate rule. The CLI applies mutate rules first and validates the mutated resource, like the live cluster does. Write a validate rule that requires `managed-by: kyverno`, then run `kyverno apply` with both policy files on `pod-good.yaml`. The validate rule passes only because the mutate rule ran first.

## How the patch is computed

Kyverno has two ways to write a mutate rule. `patchStrategicMerge` describes the wanted fields as a partial resource. Kyverno merges that partial resource into the original: maps are merged key by key, and lists of containers are matched by the `name` field. `patchesJson6902` is a list of operations such as `add` and `replace`, each with a `path`. Both methods work on the resource in memory and give the same kind of result in `-o`: the full resource after all matching mutate rules.

A mutate rule should be idempotent, which means that running it a second time on its own output changes nothing. The rule in the lab is idempotent: it sets one label to a fixed value. You can check it with the CLI. Run the policy on `resources/pod-good.yaml`, save the output, and run the policy again on the saved output. The two outputs must be equal. A rule that appends to a list, for example with a JSON patch `add` at the end of `args`, fails this check, and the live cluster would add the entry again on every update.

## Common mistakes

- Editing the resource file to "see the result" instead of using `-o`.
- Reading the printed resource as proof that a rule matched. Always confirm with the counters or a diff.
- Passing a values file whose policy or rule names differ from the policy by one character. The values are then silently unused and the variable stays undefined.
