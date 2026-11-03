# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The exact output of your commands will differ in names and timestamps, so this walkthrough describes what you should see instead of printing it.

Start the lab if it is not running:

```sh
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01
```

## Step 1: Read both report kinds and record the findings

```sh
kubectl get policyreport -A -o json | jq -r '
  .items[] as $r | $r.results[]?
  | select(.policy == "require-owner-label")
  | [.result, $r.metadata.namespace, ($r.scope.name // .resources[0].name)] | @tsv' | sort
kubectl get clusterpolicyreport -o json | jq -r '
  .items[] as $r | $r.results[]? | select(.policy == "require-namespace-team")
  | [.result, ($r.scope.name // .resources[0].name)] | @tsv' | sort
```

The first command should list `fail` lines for `a-bad` (namespace `fleet-a`) and for `b-bad` and `b-stale` (namespace `fleet-b`), and `pass` lines for `a-ok` and `b-ok`. The second should list a `fail` for `fleet-b` and a `pass` for `fleet-a`. If a list is empty or incomplete, wait a minute and run it again. Reports are generated asynchronously.

Record the findings. The ConfigMap has no `app=fleet` label, so the policy does not match it:

```sh
kubectl -n fleet-a create configmap capstone-findings \
  --from-literal=failing-configmaps=fleet-a/a-bad,fleet-b/b-bad,fleet-b/b-stale \
  --from-literal=failing-namespaces=fleet-b
```

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01 --keep
```

The check `findings-recorded` passes.

## Step 2: Remediate

```sh
kubectl -n fleet-a label configmap a-bad owner=ops
kubectl -n fleet-b label configmap b-bad owner=platform
kubectl -n fleet-b delete configmap b-stale
kubectl label namespace fleet-b team=platform
```

The label on the Namespace is an update of a cluster-scoped resource, so its result is refreshed in the `ClusterPolicyReport`. Grade the step:

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01 --keep
```

The check `violators-remediated` passes. `reports-clean` may still fail for a short moment, because the reports lag behind the resources.

## Step 3: Wait for the gate on both report kinds

Re-run the two commands from step 1 until you see only `pass` lines: two for `require-owner-label` in each namespace, none for `b-stale`, and two for `require-namespace-team`. Zero failures alone is not the gate; an empty report would also show zero failures. If a `fail` stays for several minutes, check the labels with `kubectl get configmap -A --show-labels` and `kubectl get namespace --show-labels`.

## Step 4: Flip both policies

```sh
kubectl patch clusterpolicy require-owner-label --type merge \
  -p '{"spec":{"validationFailureAction":"Enforce"}}'
kubectl patch clusterpolicy require-namespace-team --type merge \
  -p '{"spec":{"validationFailureAction":"Enforce"}}'
```

## Step 5: Prove both sides

```sh
cat > bad-cm.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-bad
  namespace: fleet-a
  labels:
    app: fleet
data:
  k: v
YAML
cat > good-cm.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-good
  namespace: fleet-a
  labels:
    app: fleet
    owner: ops
data:
  k: v
YAML
cat > bad-ns.yaml <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: fleet-c
  labels:
    demo: reports
YAML
cat > good-ns.yaml <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: fleet-c
  labels:
    demo: reports
    team: ops
YAML
for f in bad-cm good-cm bad-ns good-ns; do echo "== $f"; kubectl create --dry-run=server -f $f.yaml; done
```

`bad-cm` and `bad-ns` should be rejected with an admission error that names the policy, and `good-cm` and `good-ns` should be accepted as server-side dry runs. If a bad object is admitted, wait a few seconds for the webhook to pick up the flip and try again.

## Step 6: Grade the lab

```sh
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-050/capstone/labs/lab-01
```

All five checks should pass. Clean up when you are done:

```sh
astrona destroy ats-010-lab-015
```
