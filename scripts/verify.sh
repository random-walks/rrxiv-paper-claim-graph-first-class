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

# Locate the schema. Prefer a sibling rrxiv checkout, else fetch the
# pinned snapshot from GitHub raw.
SCHEMA=""
for sibling in \
  "$ROOT/../rrxiv/schema/cir.schema.json" \
  "$ROOT/../../rrxiv/schema/cir.schema.json" \
  "$ROOT/../../repos/rrxiv/schema/cir.schema.json"; do
  if [[ -f "$sibling" ]]; then
    SCHEMA="$sibling"
    break
  fi
done

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
elif command -v python3 >/dev/null 2>&1 && python3 -c "import jsonschema" 2>/dev/null; then
  python3 -c "
import json, sys
import jsonschema
schema = json.load(open('$SCHEMA'))
doc = json.load(open('$CIR'))
jsonschema.Draft202012Validator(schema).validate(doc)
print('OK  $CIR validates against cir.schema.json')
"
elif command -v uv >/dev/null 2>&1; then
  uv run --project "$ROOT/../rrxiv-python" rrxiv validate --cir "$CIR"
else
  echo "ERROR: no validator available." >&2
  echo "Install one of:" >&2
  echo "  npm i -g ajv-cli" >&2
  echo "  pip install jsonschema" >&2
  exit 127
fi

echo "OK  CIR validates."
