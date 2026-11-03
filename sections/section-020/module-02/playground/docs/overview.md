# Overview: Selecting by Identity & Operation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno, one namespace with two Pods and three service accounts, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Kyverno v1.13.2** with its four controllers ready. No policy exists yet.

  | In `apps-ns` | Details |
  | --- | --- |
  | Pod `web-frontend` | label `tier=frontend`, `app=shop` |
  | Pod `web-backend` | label `tier=backend`, `app=shop` |
  | ServiceAccount `ci-deployer` | Role allowing `get`, `list`, `create` on Pods |
  | ServiceAccount `auditor` | ClusterRole `view`, bound by a RoleBinding in `apps-ns` |
  | ServiceAccount `ops-admin` | ClusterRole `admin`, bound by a RoleBinding in `apps-ns` |

## Helpers

Paste these once in each new terminal. `probe_pod NAME TIER IMAGE [IDENTITY]` asks the API server (and so Kyverno) whether it would admit a Pod, using server-side dry-run so nothing is stored. The optional fourth argument is a ServiceAccount in `apps-ns` to impersonate. A rejection names the policy that blocked it.

```sh
probe_pod() {
  local as=()
  [ -n "${4:-}" ] && as=(--as="system:serviceaccount:apps-ns:$4")
  kubectl "${as[@]}" run "$1" --image="$3" -n apps-ns --labels="tier=$2" --dry-run=server
}
```

Use them like this: `probe_pod p1 frontend nginx`, `probe_pod p2 frontend nginx ci-deployer`.

## Practice tasks

- Write an Enforce rule requiring `registry.internal/*` images, scoped with `selector.matchLabels: {tier: frontend}`. Probe a frontend and a backend Pod with the same image.
- Switch the selector to `matchExpressions` with `operator: In`, then `NotIn`, then `DoesNotExist`, and predict the probe results first.
- Add `operations: [CREATE]` and run `kubectl label pod web-backend tier=frontend --overwrite -n apps-ns --dry-run=server`. Then switch to `[CREATE, UPDATE]` and repeat.
- Add `exclude` with a `subjects` ServiceAccount entry for `ci-deployer` and prove it with `probe_pod p3 frontend nginx ci-deployer`.
- Replace the subject exclude with `exclude.any` + `clusterRoles: [admin]` and probe as `ops-admin`. Remember the policy needs `background: false`.
- Put `resources` and `subjects` as two separate entries under `match.any` and observe how many requests are suddenly selected. Fix it with `all`.
- Run `kubectl auth whoami --as=system:serviceaccount:apps-ns:ops-admin` to see the groups the API server attaches to that identity.
