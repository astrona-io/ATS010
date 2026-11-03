# PolicyExceptions in Depth

A rule can be right for 99 percent of a cluster and wrong for one known resource, such as a migration Job that must run without limits or a legacy workload that is still being fixed. This part shows how to make that exception visible, narrow and reviewable, and how to prove that it works.

## Why an exception object

You can carve out a resource by editing the `match` or `exclude` block of the policy. That works, but the reason for the carve-out then lives inside the policy that is supposed to be the source of truth, and every future reader must work out why it is there.

A `PolicyException` (`apiVersion: kyverno.io/v2`) is a separate object. It names a policy and one or more rules of that policy, and it says which resources are exempt from just those rules. It has its own name, its own namespace and its own history. A reviewer can list all exceptions in the cluster without reading any policy.

## Enable PolicyExceptions first

Kyverno does not honour PolicyExceptions by default. You switch the feature on with two container arguments of the admission controller: `--enablePolicyException=true` turns it on, and `--exceptionNamespace=<namespace>` limits where Kyverno accepts exception objects from. An exception created in any other namespace is ignored. This is a blast-radius control: without it, anyone who may create a PolicyException anywhere could open a hole in any policy.

<!-- astrona:playground:renew -->

Patch the Deployment and wait for the new Pod. Changing a Pod template makes Kubernetes start a new rollout:

```sh
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=background-ns"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

The last command prints the argument list, which now ends with the two new flags. In a Helm installation the same switches are chart values (`features.policyExceptions.enabled` and `features.policyExceptions.namespace`). The scan that fills reports is done by the reports controller, so check its arguments too if excepted resources still show as failing in reports.

## The fields of a PolicyException

A PolicyException has three parts under `spec`.

| Field | What it does |
| --- | --- |
| `exceptions` | A list. Each entry has a `policyName` and a list of `ruleNames`. The exception only applies to those rules of that policy. |
| `match` | Which resources are exempt. It has the same `any` and `all` blocks as a policy, with `resources` selecting `kinds`, `names`, `namespaces` or a label `selector`. |
| `conditions` | Optional extra conditions that must be true for the exception to apply. |

Kyverno 1.13 may also have a `background` field that says whether the exception counts for background scans. Check the real schema in your cluster instead of trusting memory:

```sh
kubectl explain policyexception.spec
```

The important detail is the rule names. A `ruleNames` entry is matched by name against the rules of the policy, and that includes the generated rules. If the policy `require-limits-enforce` has the rule `check-limits`, the Deployment check runs under the generated rule `autogen-check-limits`. An exception that names only `check-limits` exempts the Pod check and leaves the Deployment check in place. The Deployment is then still blocked. List both names. Wildcards in `ruleNames` are accepted by Kyverno, but exact names keep the exception narrow.

## Write one and prove it works

The steps below use an `Enforce` policy named `require-limits-enforce` with the rule `check-limits`, which matches Pods in `background-ns` and requires CPU and memory limits. Apply it first if it does not exist. The Deployment `legacy-worker` must still have no limits.

Save this as `allow-legacy-worker.yaml`. It exempts the Pod and the Deployment named `legacy-worker*`, in `background-ns`, from the Pod rule and its generated rule:

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: allow-legacy-worker
  namespace: background-ns
spec:
  exceptions:
    - policyName: require-limits-enforce
      ruleNames:
        - check-limits
        - autogen-check-limits
  match:
    any:
      - resources:
          kinds:
            - Pod
            - Deployment
          names:
            - "legacy-worker*"
```

Apply it and look at what exists:

```sh
kubectl apply -f allow-legacy-worker.yaml
kubectl get policyexception -A
```

Now make the Deployment roll a new Pod, which Kyverno must admit again. The Pod still has no limits, so only the exception lets it through:

```sh
kubectl -n background-ns patch deployment legacy-worker -p '{"spec":{"template":{"metadata":{"annotations":{"force-reroll":"1"}}}}}'
kubectl -n background-ns rollout status deployment/legacy-worker --timeout=120s
```

The rollout finishes. A Deployment with another name, such as `new-worker`, does not match `legacy-worker*` and is still rejected.

## Keep exceptions narrow and reviewable

An exception has no expiry. Treat it as a record of a decision. Match the exact name or a tight prefix, name only the rules you need, and keep the exception in the namespace that you allowed with `--exceptionNamespace`. Review them with `kubectl get policyexception -A`. A result in a `PolicyReport` for an excepted resource is normally recorded as `skip`, so the report still shows that a rule was bypassed and by which resource.

You now know how to enable exceptions, write them with the right rule names and keep them small. The only step left is to use these skills together on a real task.

## Common pitfalls

> [!WARNING]
> - Creating a PolicyException before enabling the feature. The API server accepts the object because it is a valid resource, but it has no effect and the rule keeps blocking.
> - Creating the exception in a namespace that is not the `--exceptionNamespace`. Kyverno ignores it.
> - Naming only the Pod rule for a Deployment. The Deployment check runs under the `autogen-` rule, so include that name as well.
> - Using a broad `names: ["*"]` match. It turns the exception into a hole in the policy.

## Your mission: Background Scan & PolicyException Lab

You can now apply a policy to a cluster that already has workloads, read autogen rules and exempt a legacy workload with a scoped exception. The mission asks you to apply an `Enforce` policy against a legacy Deployment, prove the background scan reports it without touching it, prove a new Deployment is blocked, enable PolicyExceptions and use one to let the legacy Deployment roll a new Pod.

Pause the playground, then run and submit the lab:

```sh
astrona stop ats-010-playground-010-02
astrona run --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git git@github.com:astrona-io/ATS010.git -c sections/section-010/module-02/labs/lab-01
```

When the lab passes, clean up and resume your playground:

```sh
astrona destroy ats-010-lab-002
astrona start ats-010-playground-010-02
```
