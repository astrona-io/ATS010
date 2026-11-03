# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`, `curl` and `tar` on your machine. The lab bootstrap downloads the Kyverno CLI v1.13.2 from GitHub, so the machine needs internet access.
- You can write a Kyverno `ClusterPolicy` with a `validate` rule and a `mutate` rule.

The bootstrap installs Kyverno v1.13.2 in a single-node kind cluster, installs the `kyverno` command, and creates the working directory `$HOME/kyverno-lab/m1`. If the install of the CLI fails, the bootstrap stops with an error message.
