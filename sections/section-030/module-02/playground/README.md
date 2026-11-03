# Rule-Level Settings - Playground

- **Slug:** ats-010-playground-030-02
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (`kindest/node:v1.35.8`) with Kyverno v1.13.2 installed, the namespaces `team-a`, `team-b` and `team-c`, and a Deployment `web` in `team-a` and `team-b`. All of them exist before any policy does, which is the point: you watch what `generateExisting`, `mutateExistingOnPolicyUpdate` and `applyRules` do with resources that were already there. No `ClusterPolicy` exists. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-030-02
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, grants the background controller its extra rights, creates the pre-existing objects |
| `docs/overview.md` | What the environment contains, helpers and practice tasks |
