# rrxiv paper template

GitHub template repository for a single rrxiv paper. **One repo per rrxiv publication** is the recommended convention: papers stay self-contained, get their own commit history, can be reviewed via PRs, and their builds can be reproduced from a fresh clone.

Use this template by clicking "Use this template → Create a new repository" on GitHub, or by cloning and reinitialising git history.

For the conventions every paper repo follows (the three required build artifacts, the dependency-edge format, CI release setup, versioning), see [`PUBLISHING.md`](https://github.com/random-walks/rrxiv/blob/main/PUBLISHING.md) in the protocol repo. This README covers the template itself; PUBLISHING.md covers what every paper repo should produce.

## Repo layout

```
your-paper/
├── paper/
│   ├── main.tex              # the paper itself
│   ├── refs.bib              # bibliography
│   ├── figures/              # figure assets (PDF, PNG, SVG)
│   └── rrxiv.cls             # vendored from random-walks/rrxiv@HEAD
├── scripts/
│   ├── build.sh              # tectonic main.tex → build/main.pdf
│   ├── extract-cir.sh        # rrxiv parse → build/main.cir.json
│   └── verify.sh             # ajv / python-jsonschema validate
├── build/                    # outputs (gitignored)
│   ├── main.pdf
│   ├── main.rrxiv.aux
│   └── main.cir.json
├── .github/workflows/
│   └── build.yml             # CI: build PDF + extract + validate CIR
├── rrxiv-meta.json           # standalone metadata (slug, license, topics)
├── CITATION.cff              # GitHub-native citation file
├── LICENSE-CONTENT           # CC-BY-4.0 by default — applies to paper text + figures
├── LICENSE-CODE              # MIT by default — applies to .cls, scripts, CI
└── README.md                 # this file (replace with your paper's README)
```

## Quick start (after using template)

```sh
# 1. Clone your new repo.
git clone https://github.com/<your-org>/<your-paper>.git
cd <your-paper>

# 2. Build the PDF (requires tectonic — see scripts/build.sh).
./scripts/build.sh

# 3. Extract the Canonical Intermediate Representation.
./scripts/extract-cir.sh

# 4. Validate against rrxiv schemas.
./scripts/verify.sh
```

CI runs all three on every push and fails the build if the CIR doesn't validate.

## Fill in `rrxiv-meta.json`

The standalone metadata describes the paper to any rrxiv instance that ingests it. Required fields:

- `id_slug` — leave as `null`; the canonical instance mints one on first submission.
- `title` — paper title.
- `authors` — list of `{name, orcid?, is_agent?, affiliation?}`.
- `license` — content licence (default `CC-BY-4.0`).
- `topics` — array of strings, e.g. `["math.GM", "history-of-mathematics"]`.

The `rrxiv-meta.json` is the human-friendly cousin of the auto-extracted CIR. The build pipeline merges it with the parsed `.rrxiv.aux` to produce `build/main.cir.json`.

## Updating the vendored class

`paper/rrxiv.cls` is a snapshot of `random-walks/rrxiv@HEAD:template/rrxiv.cls`. To refresh:

```sh
curl -fsSL \
  https://raw.githubusercontent.com/random-walks/rrxiv/main/template/rrxiv.cls \
  -o paper/rrxiv.cls
```

Pin the version by checking in the commit SHA via a comment in the file's header, e.g.:

```latex
% Vendored from random-walks/rrxiv @ <SHA>, $(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

## How this paper gets into an rrxiv instance

Three paths:

1. **`./scripts/submit.sh` (recommended)** — wraps `rrxiv submit` with the right `--revision-of` resolution from `rrxiv-meta.json`. Requires `rrxiv login orcid` (or `rrxiv login agent`) against your target server. See [`docs/REVISION-WORKFLOW.md`](docs/REVISION-WORKFLOW.md) for the v2/v3/… cycle.
2. **Manual `POST /api/v0/submissions`** — multipart with the CIR + source tarball + your bearer token. The wire format is documented in [RRP-0016](https://github.com/random-walks/rrxiv/blob/main/proposals/0016-submission-request-schema.md). `./scripts/submit.sh` is just a thin wrapper around this.
3. **Sidecar fetch (canonical instance only)** — for the canonical reference instance, the seed loader at [`rrxiv-instance/scripts/seed-from-manifest.sh`](https://github.com/random-walks/rrxiv-instance/blob/main/scripts/seed-from-manifest.sh) clones known paper repos and ingests them directly. Useful for bootstrapping but not the long-run path.

### Quick start (v1 submission)

```bash
./scripts/build.sh
./scripts/extract-cir.sh
./scripts/verify.sh
rrxiv login orcid --server https://api.rrxiv.com/api/v0
./scripts/submit.sh --dry-run     # validate against the server first
./scripts/submit.sh               # commit
```

### Revising (v2, v3, …)

```bash
# Bump \rrxivversion{v2} in paper/main.tex, edit content, rebuild,
# then:
./scripts/submit.sh --revision-summary "fixed off-by-one in Claim 4"
```

The script auto-detects the prior server `paper_id` from `rrxiv-meta.json#versions` (populated after your first submission) and passes `--revision-of`. The server attaches a structured `revision_diff` inline and synthesises a `revision_summary` annotation. See [`docs/REVISION-WORKFLOW.md`](docs/REVISION-WORKFLOW.md) for the full story.

## Licensing

The template uses dual licensing as a default — change either file if your paper warrants different terms:

- **Content** (`paper/`, figures, `rrxiv-meta.json`) under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).
- **Code** (`scripts/`, `.github/workflows/`, `.cls`) under MIT.

## Conventions

- **Branching:** main is the published trunk; use `draft/<topic>` branches for in-progress edits; tag immutable releases as `v1`, `v2` etc. corresponding to the rrxiv `version` field.
- **Commit messages:** plain English, present tense. Reference the rrxiv paper id in the body when it exists.
- **PRs:** large revisions should be PRs even when there's one author, so the discussion thread is preserved.
- **Versioning:** when material substance changes (a claim is added/removed/contradicted-by-author), bump to a new `v` tag and write a release note. Minor copy edits stay on the same version.
