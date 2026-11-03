# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`.
- Network access: the lab downloads the Kyverno v1.13.2 release manifest from GitHub and pulls the Kyverno images.
- You know the idea of a `ClusterPolicy` with `match` blocks, and the difference between a `mutate` and a `validate` rule.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Kyverno. The commands for the lab are in the README of this folder. Startup takes a few minutes because of the Kyverno install.
