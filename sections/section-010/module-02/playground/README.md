# Applying Beyond Admission - Playground

- **Slug:** ats-010-playground-010-02
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno v1.13.2 installed and a namespace `background-ns` holding two running Deployments, `legacy-worker` and `report-worker`, with no resource limits. No policy exists and PolicyException support is not enabled. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno v1.13.2, waits for it, seeds `background-ns` |
| `docs/overview.md` | What the environment contains, helpers and practice tasks |
