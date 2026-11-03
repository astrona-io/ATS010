# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory and network access to download Kyverno v1.13.2 during bootstrap.
- `kubectl`.
- You have read Module 1 of Section 020: `kinds`, `names` and wildcards, `namespaces` versus `namespaceSelector`, and how fields in one `resources` block combine.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno v1.13.2 and the namespaces `shop-prod` and `shop-dev`. The commands for the lab are in the README of this folder.
