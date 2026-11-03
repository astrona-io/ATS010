# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The exact output of your commands will differ in names and timestamps, so this walkthrough describes what you should see instead of printing it.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01
```

## Step 1: Make sure the reports exist

List both report kinds:

```sh
kubectl get policyreport -A
kubectl get clusterpolicyreport
```

You should see reports in the `fleet-reports` namespace and at least one cluster-scoped report. If a list is empty, wait a minute and run it again. Reports are generated asynchronously, and the first results come from a background scan. Also check that both policies are `Ready`:

```sh
kubectl get clusterpolicy
```

Grade the starting state; the checks `reports-present` and `resources-untouched` pass when the environment is healthy:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01 --keep
```

## Step 2: Find the failing ConfigMaps

```sh
kubectl -n fleet-reports get policyreport -o json | jq -r '
  .items[] as $r | $r.results[]?
  | select(.policy == "require-owner-label" and .result == "fail")
  | ($r.scope.name // .resources[0].name)' | sort -u
```

You should see two names: `legacy-delta` and `legacy-echo`. The expression reads the name from `scope` first and falls back to `resources[0].name`, so it works for both report layouts.

## Step 3: Count the results

```sh
kubectl -n fleet-reports get policyreport -o json | jq -r '
  [.items[].results[]? | select(.policy == "require-owner-label") | .result]
  | group_by(.) | map("\(.[0]): \(length)") | .[]'
```

You should see `fail: 2` and `pass: 3`. If you add the `summary` counters of the reports instead, you get the same totals, because every result is also counted in the `summary` of its own report. A single report's counters are not enough when there are many reports.

## Step 4: Find the failing Namespaces

```sh
kubectl get clusterpolicyreport -o json | jq -r '
  .items[] as $r | $r.results[]?
  | select(.policy == "require-namespace-team" and .result == "fail")
  | ($r.scope.name // .resources[0].name)' | sort -u
```

You should see `reports-bad`. Namespaces are cluster-scoped, so `kubectl get policyreport -A` never lists them.

## Step 5: Record the findings

```sh
kubectl -n fleet-reports create configmap report-findings \
  --from-literal=failing-configmaps=legacy-delta,legacy-echo \
  --from-literal=pass-count=3 \
  --from-literal=fail-count=2 \
  --from-literal=failing-namespaces=reports-bad
```

The ConfigMap has no `app=fleet` label, so `require-owner-label` does not match it.

## Step 6: Grade the lab

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-01/labs/lab-01
```

All five checks should pass. If a findings check fails, its message prints the value it found and the value the report shows. Read both, then fix the key. If it says the report currently shows no failures, the reports are still arriving; wait and submit again.

Clean up when you are done:

```sh
astrona destroy ats-010-lab-013
```
