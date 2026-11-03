# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`, `curl` and `tar` on your machine. The bootstrap downloads the Kyverno CLI v1.13.2 from GitHub.
- You finished both modules of this section.

The bootstrap installs Kyverno v1.13.2 in a single-node kind cluster, installs the `kyverno` command, and creates `$HOME/kyverno-lab/capstone`.
