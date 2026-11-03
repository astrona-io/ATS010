#!/usr/bin/env bash
# Applies the reference solution policy. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Policy applied."
