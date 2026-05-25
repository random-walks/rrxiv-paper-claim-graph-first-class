#!/usr/bin/env bash
# Build the paper PDF + sidecar with tectonic.
#
# Outputs:
#   build/main.pdf
#   build/main.rrxiv.aux
#
# Requires: tectonic (https://tectonic-typesetting.github.io/).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v tectonic >/dev/null 2>&1; then
  echo "ERROR: tectonic not found in PATH." >&2
  echo "Install: brew install tectonic   |   cargo install tectonic" >&2
  exit 127
fi

mkdir -p "$ROOT/build"

tectonic -X compile \
  --keep-intermediates \
  --keep-logs \
  --outdir "$ROOT/build" \
  "$ROOT/paper/main.tex"

echo "OK  build/main.pdf"
if [[ -f "$ROOT/build/main.rrxiv.aux" ]]; then
  echo "OK  build/main.rrxiv.aux"
else
  echo "warn: no main.rrxiv.aux emitted — does paper/main.tex \\usepackage{rrxiv}?" >&2
fi
