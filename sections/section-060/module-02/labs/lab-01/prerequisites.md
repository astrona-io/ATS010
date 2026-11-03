# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl`, `curl` and `tar` on your machine. The bootstrap downloads the Kyverno CLI v1.13.2 from GitHub.
- You finished Module 1 or you can run `kyverno apply` on a policy and a resource file.

The bootstrap installs Kyverno v1.13.2 in a single-node kind cluster, installs the `kyverno` command, and creates the working directory `$HOME/kyverno-lab/m2` with two policies and three Pod manifests.
