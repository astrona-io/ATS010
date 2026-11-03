# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The exact output of your commands will differ in names and timestamps, so this walkthrough describes what you should see instead of printing it.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01
```

## Step 1: Read the reports and count the failures

```sh
kubectl -n rollout-lab get policyreport -o json | jq -r '
  .items[] as $r | $r.results[]? | select(.policy == "require-owner-label")
  | [.result, ($r.scope.name // .resources[0].name)] | @tsv' | sort
```

You should see one `pass` line for `ok-1` and three `fail` lines for `bad-1`, `bad-2` and `bad-3`. If the list is empty, wait a minute and run it again; reports are generated asynchronously. Do not continue until you see all four.

## Step 2: Record the gate numbers

The number of failures is three, and you flip the policy only when it is zero:

```sh
kubectl -n rollout-lab create configmap gate-record \
  --from-literal=violators-found=3 \
  --from-literal=fail-at-flip=0
```

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01 --keep
```

The check `gate-record` passes. Do not worry that `fail-at-flip=0` is written before you have flipped; it is a promise that you keep in step 5.

## Step 3: Fix the violators

```sh
kubectl -n rollout-lab label configmap bad-1 owner=ops
kubectl -n rollout-lab label configmap bad-2 owner=platform
kubectl -n rollout-lab delete configmap bad-3
```

Adding a label is an update of the ConfigMap. The policy matches updates too, so the update is evaluated and the result is refreshed. Deleting the ConfigMap removes its result. Grade the step:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01 --keep
```

The check `violators-remediated` passes. `reports-clean` may still fail for a short moment, because the reports lag behind the resources.

## Step 4: Wait for the gate

Re-read the reports until the picture is clean:

```sh
kubectl -n rollout-lab get policyreport -o json | jq -r '
  .items[] as $r | $r.results[]? | select(.policy == "require-owner-label")
  | [.result, ($r.scope.name // .resources[0].name)] | @tsv' | sort
```

You want three `pass` lines (`ok-1`, `bad-1`, `bad-2`), no `fail` line and no line for `bad-3`. This is the gate: zero failures and evidence of passes. If a `fail` stays for several minutes, the label did not reach the right ConfigMap; check with `kubectl -n rollout-lab get configmap --show-labels`.

## Step 5: Flip to Enforce

```sh
kubectl patch clusterpolicy require-owner-label --type merge \
  -p '{"spec":{"validationFailureAction":"Enforce"}}'
```

Confirm it:

```sh
kubectl get clusterpolicy require-owner-label -o jsonpath='{.spec.validationFailureAction}'; echo
```

You should see `Enforce`.

## Step 6: Prove both sides

Save a violator and a compliant ConfigMap:

```sh
cat > bad.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-bad
  namespace: rollout-lab
  labels:
    app: fleet
data:
  k: v
YAML
cat > good.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-good
  namespace: rollout-lab
  labels:
    app: fleet
    owner: ops
data:
  k: v
YAML
kubectl create --dry-run=server -f bad.yaml
kubectl create --dry-run=server -f good.yaml
```

The first command should be rejected with an admission error that names `require-owner-label`, and the second should be accepted as a server-side dry run. If the first one is admitted, wait a few seconds for the webhook to pick up the flip and try again.

## Step 7: Grade the lab

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/module-02/labs/lab-01
```

All five checks should pass. Clean up when you are done:

```sh
astrona destroy ats-010-lab-014
```
