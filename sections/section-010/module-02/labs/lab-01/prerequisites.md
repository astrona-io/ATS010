# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Kyverno v1.13.2 release manifest from GitHub, so the machine needs access to GitHub.
- You can apply a `ClusterPolicy`, you know the difference between `Enforce` and `Audit`, and you can patch a Deployment with `kubectl patch`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno and a namespace `background-ns` that holds the Deployment `legacy-worker`. The start takes a few minutes. The commands are in the README of this folder.
