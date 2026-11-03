# Apply Policies To Files With kyverno apply - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-010-playground-060-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Kyverno v1.13.2 installed and its four controllers ready. The Kyverno CLI v1.13.2 is installed on the machine, and `$HOME/kyverno-lab/m1` holds the example files. No policy is applied to the cluster. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-010-playground-060-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime and bootstrap scripts) |
| `bootstrap/01-install-kyverno.sh` | Installs Kyverno v1.13.2 and waits for the four deployments |
| `bootstrap/02-install-kyverno-cli.sh` | Downloads the Kyverno CLI v1.13.2 release tarball (arch detection) and installs it to a directory on PATH |
| `bootstrap/03-seed-working-directory.sh` | Writes the example files to `$HOME/kyverno-lab/m1` |
| `docs/overview.md` | What the environment contains and practice tasks |
