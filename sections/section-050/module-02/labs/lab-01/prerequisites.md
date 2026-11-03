# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory; Kyverno runs four controllers.
- `kubectl` and `jq` on the machine that runs the commands.
- You know how to read a `PolicyReport` with `jq` and what `validationFailureAction` does.
- You have read the module: admission versus background-scan results, how results age when a resource is fixed or deleted, and the Audit-to-Enforce gate.

The lab starts a single-node kind cluster (Kubernetes 1.35), installs Kyverno v1.13.2 from its release manifest, and waits for the first reports. Startup takes a few minutes because Kyverno's images are pulled. The commands for the lab are in the README of this folder.
