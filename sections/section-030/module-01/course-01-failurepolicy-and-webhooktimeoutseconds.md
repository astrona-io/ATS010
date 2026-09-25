# Part 1 — failurePolicy & webhookTimeoutSeconds

> Prerequisite: [Landing page](./course.md). Next: [Part 2 — schemaValidation & Policy-wide background](./course-02-schemavalidation-and-policy-wide-background.md).

## Every admission decision is a network call

When Kyverno is installed, it registers itself as a `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` with the Kubernetes API server. From that point on, every request that could match a live policy is paused mid-flight while the API server calls out to Kyverno over HTTPS and waits for an answer: allow, deny, or patch-and-allow.

That call can go wrong in two ordinary ways: it can take too long, or Kyverno can be completely unreachable (a rollout in progress, a crashed pod, a networking issue). Two policy-level settings decide what the API server does in either case.

## webhookTimeoutSeconds: how long to wait

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label-strict
spec:
  webhookTimeoutSeconds: 5
  failurePolicy: Fail
  validationFailureAction: Enforce
  rules: [ ... ]
```

`spec.webhookTimeoutSeconds` sets how many seconds the API server will wait for Kyverno's response before treating the call as failed. It defaults to `10` and can go as high as `30`. This is not a Kyverno-side setting you tune for performance tuning's sake — it directly controls the window in which a slow-but-not-dead Kyverno instance still gets to answer normally versus being treated as unreachable.

A shorter timeout makes your cluster more responsive to a genuinely stuck webhook (it fails fast instead of making every `kubectl apply` in the cluster hang), but it also makes a policy more sensitive to ordinary latency spikes — a momentarily busy Kyverno pod might get treated as "failed" even though it would have answered a second later.

## failurePolicy: what happens after a timeout or an unreachable webhook

```yaml
spec:
  failurePolicy: Fail    # or: Ignore
```

`spec.failurePolicy` decides what the API server does once it has given up waiting (or the webhook connection itself failed):

| Value | Behavior | Common name |
| --- | --- | --- |
| `Fail` (default) | The request is **denied** | "fail closed" |
| `Ignore` | The request is **admitted anyway**, as if the policy didn't exist for that one request | "fail open" |

This is a real operational tradeoff, not a cosmetic setting:

- **`Fail`** is the safer choice for a security-critical guardrail — you would rather block deployments cluster-wide during a Kyverno outage than let a single unvetted resource slip through. But it means an outage or overload in Kyverno's admission controller can escalate into blocking *every* matching admission request across the cluster, including ones that have nothing to do with the policy's original intent.
- **`Ignore`** keeps the cluster available even if Kyverno is down, at the cost of silently and completely disabling enforcement for the duration of the outage — with no error, no warning, just requests going through as if the policy were never applied.

> [!WARNING]
> **Common pitfall**
>
> Setting `failurePolicy: Fail` on every policy in a cluster with no thought to Kyverno's own availability can turn a routine Kyverno upgrade or a resource-starved node into a cluster-wide outage of unrelated workloads. A common middle-ground practice is `Fail` only for a small number of genuinely critical guardrails, with sensible resource requests/limits and multiple replicas for Kyverno's own admission controller so that failure window stays as small as possible.

> [!TIP]
> **Try it — exploratory, not graded**
>
> This is worth seeing with your own eyes, but it is timing-sensitive and is *not* checked by this lab's validation script — do it purely to build intuition, then restore the deployment before moving on.
>
> ```sh
> kubectl -n kyverno get deployment kyverno-admission-controller
> kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=0
> ```
> With the admission controller scaled to zero, try creating a Pod that should be blocked by a `failurePolicy: Fail` policy — expect it to still be rejected (fail closed), even though Kyverno itself isn't running to evaluate it. Now try the same against a `failurePolicy: Ignore` policy — expect it to be admitted (fail open).
>
> Afterwards, restore the deployment to its original replica count:
> ```sh
> kubectl -n kyverno scale deployment kyverno-admission-controller --replicas=<original-count>
> kubectl -n kyverno rollout status deployment/kyverno-admission-controller
> ```

## Reference

- `kubectl explain clusterpolicy.spec.failurePolicy`
- `kubectl explain clusterpolicy.spec.webhookTimeoutSeconds`
