# Background Scanning Already-Existing Resources

Enforce and Audit act at one moment: when the API server processes a create or update request. A policy that you apply today cannot see anything created yesterday. This part explains the setting that closes that gap, what it reports, and where it stops.

## Admission control has no memory of the past

Apply a new policy to a cluster that has been running for a year. Every resource created before that moment is invisible to admission control. Kyverno does not re-check them because a new policy appeared.

`background: true` closes the gap. It is the default for every policy, unless you set it to `false`. With it, Kyverno controllers re-evaluate the matching resources that already exist in the cluster against the rule, independent of admission. In Kyverno 1.13 the reports controller (`kyverno-reports-controller`) performs this scan. It runs periodically and also when a policy changes, so a result can take a short time to appear after you apply the policy.

<!-- astrona:playground:renew -->

The namespace `background-ns` already holds two Deployments with no resource limits: `legacy-worker` and `report-worker`. Save this as `require-limits-audit.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-limits-audit
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: check-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaces:
                - background-ns
      validate:
        message: "Every container must set resources.limits.cpu and resources.limits.memory."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    cpu: "?*"
                    memory: "?*"
```

Apply it and read the reports:

```sh
kubectl apply -f require-limits-audit.yaml
kubectl get clusterpolicy require-limits-audit
kubectl get policyreport -n background-ns
```

Wait a little and run the last command again if the list is empty. The Pods of both Deployments appear as failing results. Check that nothing changed in the Deployments:

```sh
kubectl get deployment -n background-ns
```

Both Deployments are untouched. Nothing was deleted, edited or blocked.

## What background scanning does and does not do

Background scanning has clear limits. Knowing them avoids wrong expectations.

- It only applies to `validate` rules. `mutate` and `generate` rules have their own settings for existing resources (`mutateExistingOnPolicyUpdate` for mutate and `generateExisting` for generate), which are separate mechanisms.
- It never blocks, deletes or changes anything, whatever the value of `validationFailureAction`. A scan only writes results into a `PolicyReport` (namespaced resources) or `ClusterPolicyReport` (cluster-scoped resources).
- A result follows the resource. When you fix the workload, the next scan records `pass` for it. When you delete the workload, its result goes away. The report is the current state, not a log of the past.

You can see the last point on your own. Add resource limits to `report-worker` and wait for the next scan. Leave `legacy-worker` as it is, because you use it again later:

```sh
kubectl set resources deployment report-worker -n background-ns --limits=cpu=100m,memory=64Mi
kubectl get policyreport -n background-ns -o wide
```

The rollout creates a new Pod, which Kyverno checks at admission and records as `pass`. The `summary` counts in the reports move from `fail` to `pass`. The old Pod's report disappears with the old Pod.

## Rules that cannot be scanned

Some rules depend on information that only exists in an admission request, such as the user who sent the request. A resource that already sits in the cluster has no request. Kyverno rejects a policy at apply time when a rule with `background: true` uses request-specific variables such as the user information. For such a rule, set `background: false`. The rule then only evaluates resources at the moment they are admitted.

You may also choose `background: false` on purpose, when you want a rule to apply only going forward and never report on history.

`background` is also visible in the output of `kubectl get clusterpolicy`, in the `BACKGROUND` column, next to `ADMISSION`. `ADMISSION` shows whether the rules are checked at admission.

You can now see old resources through reports. The next question is why a rule written for `Pod` also affects Deployments, which is what autogen does.

## Common pitfalls

> [!WARNING]
> - Assuming `background: false` with `Audit` means nothing happens. The rule still evaluates every new admission. `background` controls the re-check of existing resources. `validationFailureAction` controls the decision at admission. They are independent.
> - Expecting a scan to fix or remove a violating resource. It only reports.
> - Reading the report straight after the apply. The scan needs a moment, so an empty list does not mean "clean".
