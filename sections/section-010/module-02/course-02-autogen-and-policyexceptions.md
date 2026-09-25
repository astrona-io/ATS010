# Part 2 — Autogen for Pod Controllers & PolicyExceptions

> Prerequisite: [Part 1 — Background Scanning Already-Existing Resources](./course-01-background-scanning-already-existing-resources.md). Next: [Section 020 — Resource Selection](../../section-020/README.md).

## The problem autogen solves

In practice, almost nobody creates a bare `Pod` directly — they create a `Deployment`, a `StatefulSet`, a `DaemonSet`, a `Job`, or a `CronJob`, and the Pod is spawned indirectly by that controller. If you write a rule with `match.resources.kinds: [Pod]`, expecting it to protect your workloads, but only actually admission-check bare Pods, you have a large blind spot: someone creates a non-compliant Deployment, its ReplicaSet creates a non-compliant Pod, and — depending on cluster timing — that Pod may slip through before your rule ever gets a clean shot at the *originating* request.

Kyverno solves this automatically. When a rule's `match` includes `kinds: [Pod]`, Kyverno's policy controller automatically generates additional rules — visible with an `autogen-` name prefix — that apply the same logic to the Pod-template-owning controllers: `Deployment`, `ReplicaSet`, `StatefulSet`, `DaemonSet`, `Job`, and `CronJob`. Your one authored rule ends up protecting all of them at admission time, not just bare Pods.

> [!TIP]
> **Try it — see autogen's handiwork**
>
> ```sh
> kubectl get clusterpolicy require-resource-limits -o yaml
> ```
> Look for:
> - An annotation `pod-policies.kyverno.io/autogen-controllers` listing the controller kinds autogen covers.
> - Extra entries under `status` (or additional rule names, depending on Kyverno version) prefixed `autogen-`, mirroring your original rule.

## Controlling or disabling autogen

You can set the `pod-policies.kyverno.io/autogen-controllers` annotation explicitly on the policy to restrict which controllers autogen targets (for example, only `Deployment,StatefulSet`), or set it to `"none"` to disable autogen entirely for that policy — leaving your rule scoped to bare Pods only, exactly as written. You'd disable it if you have a genuinely Pod-specific reason for the rule (something that only makes sense checked at the Pod level) and don't want the generated variants cluttering `kubectl get clusterpolicy -o yaml` output or evaluating against controllers you don't care about.

## PolicyExceptions: a scoped override without editing the policy

Sometimes a rule is correct for 99% of the cluster and wrong for one specific, known resource — a migration Job that genuinely needs to run without resource limits, or a legacy workload mid-remediation. Editing the policy's `match`/`exclude` to carve out that one resource works, but it means every future reader of the policy has to reverse-engineer *why* that carve-out exists, and the exemption lives buried inside the policy that's supposed to be the enforcement source of truth.

`kind: PolicyException` (`apiVersion: kyverno.io/v2`) is a separate, standalone object that references a specific policy and rule by name and exempts specific matching resources from just that rule — visible, auditable, and independently reviewable in its own manifest.

PolicyExceptions are **not enabled by default**. You must explicitly enable them on the Kyverno installation by adding two container arguments to the `kyverno-admission-controller` Deployment:

```sh
kubectl -n kyverno patch deployment kyverno-admission-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enablePolicyException=true"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--exceptionNamespace=platform-ns"}
]'
kubectl -n kyverno rollout status deployment/kyverno-admission-controller --timeout=180s
```

`--exceptionNamespace` restricts where Kyverno will honor `PolicyException` objects from — an exception created outside that namespace is simply ignored. This is a deliberate blast-radius control: without it, anyone with permission to create a `PolicyException` anywhere in the cluster could quietly punch a hole in any policy.

A minimal exception looks like this:

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: allow-migration-job
  namespace: platform-ns
spec:
  exceptions:
    - policyName: require-resource-limits
      ruleNames:
        - check-resource-limits
  match:
    any:
    - resources:
        kinds:
          - Job
        names:
          - "migration-job*"
```

> [!WARNING]
> **Common pitfall**
>
> Creating a `PolicyException` and expecting it to work immediately, without first checking that `--enablePolicyException=true` (and a matching `--exceptionNamespace`) is actually set on the admission controller. If exceptions aren't enabled, the object is accepted by the API server (it's a valid CRD) but silently has no effect — the original rule keeps enforcing as if the exception didn't exist.

## Reference

- `kubectl get clusterpolicy <name> -o yaml` — inspect the `pod-policies.kyverno.io/autogen-controllers` annotation and generated rules.
- `kubectl get deployment kyverno-admission-controller -n kyverno -o jsonpath='{.spec.template.spec.containers[0].args}'` — confirm which flags are currently set.
