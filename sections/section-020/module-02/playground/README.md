# Selecting by Identity & Operation - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno v1.13.2, installed from its release manifest by `bootstrap/prepare.sh`. Namespace `apps-ns` holds Pods `web-frontend` (`tier=frontend`) and `web-backend` (`tier=backend`) and the ServiceAccounts `ci-deployer`, `auditor` and `ops-admin` with RBAC bindings. No policy exists. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-020-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded image, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, waits for its controllers, seeds `apps-ns`, RBAC and Pods |
| `docs/overview.md` | What the environment contains and ideas to try |
