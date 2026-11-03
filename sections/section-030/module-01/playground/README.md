# Policy-Level Settings - Playground

- **Slug:** ats-010-playground-030-01
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (`kindest/node:v1.35.8`) with Kyverno v1.13.2 installed and the empty namespaces `critical-ns`, `lenient-ns` and `sandbox`. No `ClusterPolicy` exists. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-030-01
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, waits for the controllers, creates the namespaces |
| `docs/overview.md` | What the environment contains, helpers and practice tasks |
