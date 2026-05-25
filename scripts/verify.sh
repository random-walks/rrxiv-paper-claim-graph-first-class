#!/usr/bin/env bash
# Validate build/main.cir.json against the rrxiv CIR schema.
#
# Strategy:
#   1. Prefer `ajv` if available — fast, native JSON Schema 2020-12 support.
#   2. Fall back to `python -m jsonschema` if Python's jsonschema is installed.
#   3. As a last resort, ask `uv run --project ../rrxiv-python rrxiv validate`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CIR="$ROOT/build/main.cir.json"

if [[ ! -f "$CIR" ]]; then
  echo "ERROR: $CIR not found — run scripts/extract-cir.sh first." >&2
  exit 1
fi

# Locate the schema. Order:
#   1. $RRXIV_REPO env var (CI sets this).
#   2. Sibling rrxiv checkout (local dev).
#   3. `deps/rrxiv` subdir (CI workspace-relative checkout).
#   4. Fetch the pinned snapshot from GitHub raw.
SCHEMA=""
if [[ -n "${RRXIV_REPO:-}" && -f "$RRXIV_REPO/schema/cir.schema.json" ]]; then
  SCHEMA="$RRXIV_REPO/schema/cir.schema.json"
fi
if [[ -z "$SCHEMA" ]]; then
  for sibling in \
    "$ROOT/../rrxiv/schema/cir.schema.json" \
    "$ROOT/../../rrxiv/schema/cir.schema.json" \
    "$ROOT/../../repos/rrxiv/schema/cir.schema.json" \
    "$ROOT/deps/rrxiv/schema/cir.schema.json"; do
    if [[ -f "$sibling" ]]; then
      SCHEMA="$sibling"
      break
    fi
  done
fi

if [[ -z "$SCHEMA" ]]; then
  TMP="$(mktemp -d)"
  SCHEMA="$TMP/cir.schema.json"
  curl -fsSL \
    "https://raw.githubusercontent.com/random-walks/rrxiv/main/schema/cir.schema.json" \
    -o "$SCHEMA"
fi

if command -v ajv >/dev/null 2>&1; then
  ajv validate \
    --spec=draft2020 \
    -s "$SCHEMA" \
    -d "$CIR" \
    --allow-union-types
elif command -v python3 >/dev/null 2>&1 && python3 -c "import jsonschema, referencing" 2>/dev/null; then
  # Pre-load every *.schema.json in the schema dir into a Registry so
  # cross-schema $refs (cir → paper → claim → author → ...) resolve
  # against the local filesystem instead of trying to fetch
  # https://rrxiv.com/schema/v0/<name>.schema.json over the network.
  SCHEMA_DIR="$(dirname "$SCHEMA")"
  python3 - "$SCHEMA" "$CIR" "$SCHEMA_DIR" <<'PY'
import glob, json, os, sys
import jsonschema
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

schema_path, cir_path, schema_dir = sys.argv[1:4]
schema = json.load(open(schema_path))
doc = json.load(open(cir_path))

resources = []
for path in sorted(glob.glob(os.path.join(schema_dir, "*.schema.json"))):
    s = json.load(open(path))
    if "$id" in s:
        resources.append((s["$id"], Resource(contents=s, specification=DRAFT202012)))
registry = Registry().with_resources(resources)

jsonschema.Draft202012Validator(schema, registry=registry).validate(doc)
print(f"OK  {cir_path} validates against {os.path.basename(schema_path)}")
PY
elif command -v uv >/dev/null 2>&1; then
  PYREPO="${RRXIV_PYTHON_REPO:-$ROOT/../rrxiv-python}"
  if [[ ! -f "$PYREPO/pyproject.toml" && -f "$ROOT/deps/rrxiv-python/pyproject.toml" ]]; then
    PYREPO="$ROOT/deps/rrxiv-python"
  fi
  # --all-extras pulls in the CLI's transitive deps (cryptography +
  # http-message-signatures + fastapi via cli/app.py's eager imports).
  # `rrxiv validate` itself doesn't need any of them at runtime.
  uv run --project "$PYREPO" --all-extras rrxiv validate "$CIR"
else
  echo "ERROR: no validator available." >&2
  echo "Install one of:" >&2
  echo "  npm i -g ajv-cli" >&2
  echo "  pip install jsonschema" >&2
  exit 127
fi

echo "OK  CIR validates."
