# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`.
- You know `applyRules` and `generateExisting` and can write a `generate` rule with `data` and a `mutate` rule with `patchStrategicMerge`.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Kyverno v1.13.2 from its release manifest, which needs internet access. The first start takes a few minutes. Backfills are done by the background controller, so some results appear a few seconds after you apply a policy.
