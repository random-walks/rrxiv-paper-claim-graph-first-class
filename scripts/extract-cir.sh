#!/usr/bin/env bash
# Extract the Canonical Intermediate Representation (CIR) from the
# build artifacts produced by scripts/build.sh.
#
# Uses the rrxiv CLI from random-walks/rrxiv-python, published on PyPI:
#   pip install 'rrxiv>=0.2.1'   (or: uv tool install 'rrxiv>=0.2.1')
# A sibling rrxiv-python checkout still works as a dev fallback — see
# the resolution order below.
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
#   2. `rrxiv` on PATH (a PyPI install: pip or uv tool, >=0.2.1).
#   3. Sibling checkout — the local-dev convention where paper repos sit
#      next to rrxiv-python under one workspace dir.
# `rrxiv.cli.app` eagerly imports every sub-command at module load
# (annotation_post, seed, server-side projection helpers, ...), which
# pulls in cryptography + http-message-signatures + fastapi. We pass
# --all-extras so the CLI imports cleanly even though `rrxiv parse`
# doesn't actually need most of that machinery. uv caches the install.
RRXIV_CMD=""
if [[ -n "${RRXIV_PYTHON_REPO:-}" && -f "$RRXIV_PYTHON_REPO/pyproject.toml" ]]; then
  RRXIV_CMD="uv run --project $RRXIV_PYTHON_REPO --all-extras rrxiv"
elif command -v rrxiv >/dev/null 2>&1; then
  RRXIV_CMD="rrxiv"
elif command -v uv >/dev/null 2>&1; then
  for sibling in \
    "$ROOT/../rrxiv-python" \
    "$ROOT/../../rrxiv-python" \
    "$ROOT/../../repos/rrxiv-python" \
    "$ROOT/deps/rrxiv-python"; do
    if [[ -f "$sibling/pyproject.toml" ]]; then
      RRXIV_CMD="uv run --project $sibling --all-extras rrxiv"
      break
    fi
  done
fi

if [[ -z "$RRXIV_CMD" ]]; then
  echo "ERROR: rrxiv CLI not found." >&2
  echo "Options:" >&2
  echo "  1. Install from PyPI: pip install 'rrxiv>=0.2.1'" >&2
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
