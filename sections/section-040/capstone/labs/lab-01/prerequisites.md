# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`.
- Network access: the lab downloads the Kyverno v1.13.2 release manifest from GitHub and pulls the Kyverno images.
- You know `mutate` (`patchStrategicMerge`), `validate` (`pattern`), `generate` (`data`, `synchronize`) and cleanup policies (`match`, `conditions`, `schedule`), and that the Kyverno controllers need RBAC for what they create and delete.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Kyverno. The commands for the lab are in the README of this folder. Startup takes a few minutes, and a full submit can take several minutes because the checks wait for generation and the cleanup schedule.
