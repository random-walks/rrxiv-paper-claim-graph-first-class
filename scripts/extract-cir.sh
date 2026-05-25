#!/usr/bin/env bash
# Extract the Canonical Intermediate Representation (CIR) from the
# build artifacts produced by scripts/build.sh.
#
# Uses the rrxiv CLI from random-walks/rrxiv-python (`pip install rrxiv`
# or `uv tool install rrxiv` once published; for now: clone alongside
# this repo and `uv run rrxiv parse` from there).
#
# Output: build/main.cir.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEX="$ROOT/paper/main.tex"
AUX="$ROOT/build/main.rrxiv.aux"
META="$ROOT/rrxiv-meta.json"
OUT="$ROOT/build/main.cir.json"

if [[ ! -f "$AUX" ]]; then
  echo "ERROR: $AUX missing — run scripts/build.sh first." >&2
  exit 1
fi

# Resolve the rrxiv CLI. Order:
#   1. $RRXIV_PYTHON_REPO env var (CI sets this; respects any in-repo
#      override).
#   2. `rrxiv` on PATH (once published to PyPI, or a global uv install).
#   3. Sibling checkout — the local-dev convention where paper repos sit
#      next to rrxiv-python under one workspace dir.
# The CLI imports rrxiv.client at startup, which pulls in the optional
# `agent` extra (cryptography + http-message-signatures). We include
# --extra agent on every uv-based invocation so even `rrxiv parse` —
# which doesn't actually sign anything — can resolve its transitive
# imports.
RRXIV_CMD=""
if [[ -n "${RRXIV_PYTHON_REPO:-}" && -f "$RRXIV_PYTHON_REPO/pyproject.toml" ]]; then
  RRXIV_CMD="uv run --project $RRXIV_PYTHON_REPO --extra agent rrxiv"
elif command -v rrxiv >/dev/null 2>&1; then
  RRXIV_CMD="rrxiv"
elif command -v uv >/dev/null 2>&1; then
  for sibling in \
    "$ROOT/../rrxiv-python" \
    "$ROOT/../../rrxiv-python" \
    "$ROOT/../../repos/rrxiv-python" \
    "$ROOT/deps/rrxiv-python"; do
    if [[ -f "$sibling/pyproject.toml" ]]; then
      RRXIV_CMD="uv run --project $sibling --extra agent rrxiv"
      break
    fi
  done
fi

if [[ -z "$RRXIV_CMD" ]]; then
  echo "ERROR: rrxiv CLI not found." >&2
  echo "Options:" >&2
  echo "  1. Install: pip install rrxiv  (once published)" >&2
  echo "  2. Clone https://github.com/random-walks/rrxiv-python alongside this repo." >&2
  exit 127
fi

# `rrxiv parse` reads the .tex + the sidecar .rrxiv.aux and emits a
# CIR JSON document. The standalone rrxiv-meta.json is human-facing
# metadata (slug, license, topics) — the v0.x parser pulls all of it
# out of the .tex via the rrxiv.cls macros + the sidecar, so $META is
# not currently passed to the CLI. Keep $META resolved above so future
# tooling can wire it back in.
$RRXIV_CMD parse "$TEX" \
  --sidecar "$AUX" \
  --output "$OUT"

echo "OK  $OUT"
