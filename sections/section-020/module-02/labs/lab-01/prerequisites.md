# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory and network access to download Kyverno v1.13.2 during bootstrap.
- `kubectl`.
- You have read Module 2 of Section 020: `selector`, `operations`, `subjects`, `exclude`, and `kubectl --as` impersonation.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno v1.13.2, the namespace `apps-ns` and the ServiceAccount `ci-deployer`. The commands for the lab are in the README of this folder.
