# Where Results Come From and How They Age — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-050-02
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno 1.13.2 installed. The `Audit` policy `require-owner-label` already ran against five ConfigMaps in `fleet-reports`, and the `rollout-lab` namespace holds four ConfigMaps (three violate) that have no policy yet, ready for the rollout-gate exercise. Nothing to submit.

UNTESTED - built from static checks only; not yet booted.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-050-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply — there is no grading. The machine needs `kubectl` and `jq`.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno v1.13.2, waits for its controllers and webhooks, seeds resources and the Audit policies |
| `docs/overview.md` | What the environment contains, helper functions, the gate policy YAML and practice tasks |
