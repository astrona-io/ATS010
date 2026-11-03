# match/exclude Fundamentals - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno v1.13.2, installed from its release manifest by `bootstrap/prepare.sh`. Namespaces `shop-prod` (`env=prod`), `shop-dev` (`env=dev`) and `shop-stage` (`env=staging`) exist, with a few ConfigMaps whose names are deliberately misleading. No policy exists. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, waits for its controllers, seeds namespaces and ConfigMaps |
| `docs/overview.md` | What the environment contains and ideas to try |
