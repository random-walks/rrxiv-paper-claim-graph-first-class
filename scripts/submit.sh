#!/usr/bin/env bash
# submit.sh — submit this paper (or a revision) to an rrxiv instance.
#
# Wraps `rrxiv submit` from the rrxiv-python CLI (RRP-0016, RRP-0017).
# Reads rrxiv-meta.json for the prior-version paper_id when submitting
# a revision (--revision-of inferred automatically).
#
# Prerequisites:
#   1. ./scripts/build.sh       — produces build/main.pdf + .rrxiv.aux
#   2. ./scripts/extract-cir.sh — produces build/main.cir.json
#   3. `rrxiv login orcid` (or `rrxiv login agent`) against your target
#      server, so the CLI has credentials.
#
# Usage:
#   ./scripts/submit.sh                          # submit current version
#   ./scripts/submit.sh --dry-run                # validate without persisting
#   ./scripts/submit.sh --server <api_base>      # override $RRXIV_SERVER
#   ./scripts/submit.sh --revision-summary "..." # attach a v2 changelog
#
# By default the script picks up the current version's prior server
# paper_id from rrxiv-meta.json#versions (added at first submission)
# and passes it as --revision-of. To force a v1 submission even when
# history exists, pass --no-revision.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
META="$ROOT/rrxiv-meta.json"
CIR="$ROOT/build/main.cir.json"
BUNDLE="$ROOT/build/source.tar.gz"
DEFAULT_SERVER="${RRXIV_SERVER:-https://api.rrxiv.com/api/v0}"

# --- Parse args -----------------------------------------------------
SERVER="$DEFAULT_SERVER"
DRY_RUN=""
SUMMARY=""
NO_REVISION=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server)         SERVER="$2"; shift 2 ;;
    --server=*)       SERVER="${1#*=}"; shift ;;
    --dry-run)        DRY_RUN="--dry-run"; shift ;;
    --revision-summary)
                      SUMMARY="$2"; shift 2 ;;
    --revision-summary=*)
                      SUMMARY="${1#*=}"; shift ;;
    --no-revision)    NO_REVISION="1"; shift ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's|^# *||; s|^#$||'
      exit 0 ;;
    *)
      EXTRA_ARGS+=("$1"); shift ;;
  esac
done

# --- Sanity check artefacts -----------------------------------------
if [[ ! -f "$CIR" ]]; then
  echo "ERROR: $CIR missing — run ./scripts/build.sh && ./scripts/extract-cir.sh first." >&2
  exit 1
fi
if [[ ! -f "$BUNDLE" ]]; then
  echo "==> source.tar.gz missing — building from paper/ ..."
  tar -czf "$BUNDLE" -C "$ROOT" paper
fi

# --- Resolve rrxiv CLI ----------------------------------------------
RRXIV_CMD=""
if command -v rrxiv >/dev/null 2>&1; then
  RRXIV_CMD="rrxiv"
elif command -v uv >/dev/null 2>&1; then
  for sibling in \
    "$ROOT/../rrxiv-python" \
    "$ROOT/../../rrxiv-python" \
    "$ROOT/../../repos/rrxiv-python"; do
    if [[ -f "$sibling/pyproject.toml" ]]; then
      RRXIV_CMD="uv run --project $sibling rrxiv"
      break
    fi
  done
fi
if [[ -z "$RRXIV_CMD" ]]; then
  echo "ERROR: rrxiv CLI not found. Install from PyPI: pip install 'rrxiv>=0.2.1'" >&2
  echo "(or: uv tool install 'rrxiv>=0.2.1'), or clone github.com/random-walks/rrxiv-python alongside this repo." >&2
  exit 127
fi

# --- Resolve --revision-of from rrxiv-meta.json ---------------------
REVISION_OF=""
if [[ -z "$NO_REVISION" ]] && command -v jq >/dev/null 2>&1 && [[ -f "$META" ]]; then
  # Versions array convention (set by previous successful submits):
  #   "versions": [{ "version": "v1", "paper_id": "...", "submitted_at": "..." }, ...]
  PRIOR=$(jq -r '
    if (.versions // [] | length) > 0 then
      .versions | last.paper_id
    else empty end
  ' "$META")
  if [[ -n "$PRIOR" && "$PRIOR" != "null" ]]; then
    REVISION_OF="--revision-of $PRIOR"
    echo "==> Detected prior version: $PRIOR (override with --no-revision)"
  fi
fi

# --- Run --------------------------------------------------------------
echo "==> Submitting $CIR + $BUNDLE to $SERVER"
EXTRA=""
if [[ -n "$SUMMARY" ]]; then
  EXTRA="--revision-summary \"$SUMMARY\""
fi

# shellcheck disable=SC2086
eval "$RRXIV_CMD submit \"$CIR\" \"$BUNDLE\" \
  --server \"$SERVER\" \
  $DRY_RUN \
  $REVISION_OF \
  $EXTRA \
  ${EXTRA_ARGS[*]:-}"
