#!/usr/bin/env bash
# Installs the Kyverno CLI v1.13.2 on the machine that runs the lab scripts.
# Downloads the release tarball from GitHub, detects the operating system and
# the CPU architecture, and puts the `kyverno` binary in a directory on PATH.
# Fails loudly (non-zero exit, message on stderr) if any step does not work.
set -euo pipefail

VERSION="v1.13.2"
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

if command -v kyverno >/dev/null 2>&1 && kyverno version 2>/dev/null | grep -q "${VERSION#v}"; then
  echo "Kyverno CLI ${VERSION} is already installed at $(command -v kyverno)."
  exit 0
fi

case "$(uname -s)" in
  Linux) os="linux" ;;
  Darwin) os="darwin" ;;
  *) echo "ERROR: unsupported operating system: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) arch="x86_64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *) echo "ERROR: unsupported CPU architecture: $(uname -m)" >&2; exit 1 ;;
esac

url="https://github.com/kyverno/kyverno/releases/download/${VERSION}/kyverno-cli_${VERSION}_${os}_${arch}.tar.gz"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

echo "Downloading ${url}"
if ! curl -fsSL --retry 3 -o "${tmp}/kyverno-cli.tar.gz" "${url}"; then
  echo "ERROR: could not download ${url}" >&2
  exit 1
fi
if ! tar -xzf "${tmp}/kyverno-cli.tar.gz" -C "${tmp}" kyverno; then
  echo "ERROR: the archive does not contain a 'kyverno' binary" >&2
  exit 1
fi

if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  bindir="/usr/local/bin"
else
  bindir="${HOME}/.local/bin"
  mkdir -p "${bindir}"
  for profile in "${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [ -f "${profile}" ] && ! grep -q 'HOME/.local/bin' "${profile}"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${profile}"
    fi
  done
fi
install -m 0755 "${tmp}/kyverno" "${bindir}/kyverno"

export PATH="${bindir}:${PATH}"
if ! command -v kyverno >/dev/null 2>&1; then
  echo "ERROR: kyverno is not on PATH after install (looked in ${bindir})" >&2
  exit 1
fi
if ! kyverno version 2>/dev/null | grep -q "${VERSION#v}"; then
  echo "ERROR: 'kyverno version' does not report ${VERSION#v}" >&2
  exit 1
fi
echo "Installed Kyverno CLI ${VERSION} to ${bindir}/kyverno"
