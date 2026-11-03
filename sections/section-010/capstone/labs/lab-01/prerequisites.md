# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Kyverno v1.13.2 release manifest from GitHub, so the machine needs access to GitHub.
- You can apply a `ClusterPolicy` in `Enforce` and `Audit` mode, you know that a rule matching `Pod` also gets autogen rules for controllers, and you can enable and write a `PolicyException`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno, the namespaces `checkout-live` and `reporting-live`, and the Deployment `old-reporter`. The start takes a few minutes. The commands are in the README of this folder.
