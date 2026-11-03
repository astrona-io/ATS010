# Applying Validate And Mutate Policies - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno
v1.13.2 installed, the namespaces `starfleet` and `outpost`, and a ConfigMap
`crew-notes`. No policy exists. Nothing to submit.

UNTESTED - built from static checks only; not yet booted.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap script) |
| `bootstrap/prepare.sh` | Installs Kyverno v1.13.2 and creates the sandbox |
| `docs/overview.md` | What the environment contains and ideas to try |
