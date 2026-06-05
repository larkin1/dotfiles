#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating submodules..."
if ! git -C "$SCRIPT_DIR" submodule update --init --remote; then
  echo "Warning: failed to update submodules, continuing..." >&2
fi
echo "Done!"
