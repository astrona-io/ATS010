# Reading PolicyReport and ClusterPolicyReport — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-050-01
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno 1.13.2 installed. Two `Audit` policies are applied, `require-owner-label` for ConfigMaps and `require-namespace-team` for Namespaces. Seeded resources comply or violate on purpose, so both a `PolicyReport` and a `ClusterPolicyReport` have content. Nothing to submit.

UNTESTED - built from static checks only; not yet booted.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-050-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply — there is no grading. The machine needs `kubectl` and `jq`.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno v1.13.2, waits for its controllers and webhooks, seeds resources and policies |
| `docs/overview.md` | What the environment contains, helper functions and practice tasks |
