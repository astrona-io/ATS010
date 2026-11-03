# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory and network access to download Kyverno v1.13.2 during bootstrap.
- `kubectl`.
- You know `kinds`, `names`, `namespaceSelector`, `selector`, `operations`, `subjects`, `exclude`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno v1.13.2, the namespaces `store-prod` and `store-dev`, and the ServiceAccount `release-bot`. The commands for the lab are in the README of this folder.
