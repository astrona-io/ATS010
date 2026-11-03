# Summary

Admission control only sees requests. Background scanning covers what already exists. With `background: true`, which is the default, Kyverno re-evaluates existing resources against `validate` rules and writes the results into `PolicyReport` and `ClusterPolicyReport` objects. A scan never blocks, deletes or changes a resource, whatever `validationFailureAction` says. A result follows the resource: a fixed workload turns into `pass` on the next scan. Rules that need request-only information, such as user information, must use `background: false`, and `background` and `validationFailureAction` are independent settings.

Autogen makes a rule that matches `Pod` also protect the controllers that create Pods. Kyverno generates rules with an `autogen-` prefix for Deployment, DaemonSet, StatefulSet, Job and CronJob, and moves the paths to the Pod template. In version 1.13 the generated rules are in `status.autogen.rules`. The annotation `pod-policies.kyverno.io/autogen-controllers` restricts the controller list, and the value `none` turns autogen off.

A `PolicyException` exempts matching resources from named rules of a named policy, without editing the policy. The feature is off by default. It needs `--enablePolicyException=true` and `--exceptionNamespace=<namespace>` on the admission controller, and exceptions outside that namespace are ignored. The `ruleNames` list must contain the generated rule names when the exempt resource is a controller such as a Deployment. An exception has no expiry, so keep it narrow and review it with `kubectl get policyexception -A`. The key facts to remember are these:

- Background scans only report; they never change anything.
- `background: false` is needed for rules that use request-only variables.
- Generated rules start with `autogen-`; the annotation value `none` disables autogen.
- A PolicyException created while the feature is off has no effect.
- A Deployment exception must name the `autogen-` rule as well as the Pod rule.

<!-- astrona:playground:destroy -->
