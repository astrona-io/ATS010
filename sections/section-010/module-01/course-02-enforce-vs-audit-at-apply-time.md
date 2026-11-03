# Enforce vs Audit at Apply Time

When a resource breaks a policy rule, Kyverno must decide what to do with it. One setting makes that decision. This part explains that setting, shows both outcomes on a real Pod, and then describes how teams roll a new policy out without breaking a busy cluster.

## One field decides: block or record

`spec.validationFailureAction` decides what happens to a resource that fails a `validate` rule at admission time. Admission time is the moment the API server processes a create or update request.

| Value | What happens to the failing resource |
| --- | --- |
| `Enforce` | The API server rejects the request. The `kubectl` command fails with an error that names the policy, the rule and the rule's message. The resource is not created. |
| `Audit` | The API server admits the request and creates the resource. Kyverno records the violation as a result in a `PolicyReport` (namespaced resources) or a `ClusterPolicyReport` (cluster-scoped resources). |

Kyverno 1.13 also lets you set the action inside a single rule, with `validate.failureAction`. This course uses the policy-level field, because it is the one that the labs check.

Both values only affect the request being processed right now. Neither value reaches back to resources that already exist. Admission checks `CREATE` and `UPDATE` requests, so a later change to an existing resource that breaks an `Enforce` rule can be rejected too.

## See both outcomes

Start with the `Audit` policy. Save this as `require-team-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - payments
      validate:
        message: "Every Pod must have a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

<!-- astrona:playground:renew -->

Apply it, then create a Pod without the label and look for the violation:

```sh
kubectl apply -f require-team-label.yaml
kubectl run no-team-pod --image=nginx:alpine -n payments
kubectl get pod no-team-pod -n payments
kubectl get policyreport -n payments
```

The Pod exists, because `Audit` admitted it. The report lists `require-team-label` as a failing policy for it. Kyverno writes the report a few seconds after the admission, so run the last command again if the list is empty.

Now change `validationFailureAction` to `Enforce` in the file and apply it again. Create a second Pod:

```sh
kubectl apply -f require-team-label.yaml
kubectl run no-team-pod-2 --image=nginx:alpine -n payments
kubectl get pod no-team-pod-2 -n payments
```

The `kubectl run` command fails and the error names `require-team-label`. The `kubectl get` command answers `NotFound`, because the API server never stored the Pod. The first Pod, `no-team-pod`, is still running. Switching to `Enforce` did not remove it.

## Why teams ship a policy as Audit first

A new rule on a busy cluster is risky. If the `match` or the `pattern` is slightly wrong, `Enforce` can reject legitimate workloads the moment the policy goes live. In the worst case it rejects a platform component the cluster needs to run.

The usual rollout has four steps:

1. Apply the policy with `validationFailureAction: Audit`.
2. Let it run for a representative period, from hours to days, and read the `PolicyReport` results for violations you did not expect.
3. Fix the rule, or fix the workloads, until the reports match what you expect.
4. Change the action to `Enforce` and apply the policy again.

The flip in step 4 is still all-or-nothing for the whole cluster, which is the next problem to solve.

## Stage the rollout with validationFailureActionOverrides

`spec.validationFailureActionOverrides` sets a different action for chosen namespaces inside the same policy. The top-level `validationFailureAction` is the default. Each override entry has an `action` and either a list of `namespaces` or a `namespaceSelector` that matches namespace labels.

Save this as `require-team-label-staged.yaml`. It enforces in `payments` and keeps the default `Audit` for every other namespace the rule matches:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-team-label
spec:
  validationFailureAction: Audit
  validationFailureActionOverrides:
    - action: Enforce
      namespaces:
        - payments
  background: true
  rules:
    - name: check-team-label
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Every Pod must have a team label."
        pattern:
          metadata:
            labels:
              team: "?*"
```

Apply it. The rule matches Pods in every namespace now, but only `payments` blocks. A Pod in `platform-ns` without the label is admitted and reported. You move one namespace at a time to `Enforce` by adding it to the list, and you keep a single copy of the policy.

```sh
kubectl apply -f require-team-label-staged.yaml
kubectl run staged-check --image=nginx:alpine -n platform-ns
kubectl run staged-check --image=nginx:alpine -n payments
```

The first `run` succeeds. The second `run` is rejected. Delete the policy and the Pods you created when you are done: `kubectl delete clusterpolicy require-team-label`.

Remember that a rule with no `namespaces` in its `match` also matches Pods in system namespaces such as `kube-system`. That is one more reason to start in `Audit`.

You can now choose between blocking and recording and stage the change by namespace. What remains is proving what a policy did, which means reading status, reports and events.

## Common pitfalls

> [!WARNING]
> - Moving a new policy straight to `Enforce` on a live cluster. Start with `Audit` and read the reports.
> - Expecting `Enforce` to remove violators that already exist. It only changes how new create and update requests are handled.
> - Forgetting that the override list replaces the default for the named namespaces only. A namespace that is not listed uses the top-level value.
