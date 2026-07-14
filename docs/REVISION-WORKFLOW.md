# Revising your rrxiv paper

This doc covers the v2/v3/… workflow once your first version is on the canonical instance. See the top-level [`README.md`](../README.md) for first-version submission.

The protocol (RRP-0017) treats every revision as a **new immutable submission** linked to its predecessor via `previous_version`. The server computes a structured diff at ingestion time; readers can see what changed without you having to write release notes (though you should, see *Writing a good revision_summary* below).

## The short version

```bash
# 1. Edit paper/main.tex. Bump the version.
\rrxivversion{v2}

# 2. Rebuild the artefacts.
./scripts/build.sh
./scripts/extract-cir.sh
./scripts/verify.sh

# 3. Tag in git so CI publishes a v2 GitHub Release.
git commit -am "v2: tightened the bound on Claim 4"
git tag v2 && git push --tags

# 4. Submit to the canonical instance. scripts/submit.sh picks up the
#    prior paper_id from rrxiv-meta.json automatically.
./scripts/submit.sh --revision-summary "Fixed off-by-one in Claim 4."
```

Output:

```
==> Detected prior version: 01923f8e-… (override with --no-revision)
==> Submitting build/main.cir.json + build/source.tar.gz to https://api.rrxiv.com/api/v0
submission OK
  id_slug:       rrxiv:2605.00042
  paper_id:      01924a01-…
  version:       v2
  previous:      01923f8e-…
  view:          https://rrxiv.com/papers/rrxiv:2605.00042
  diff vs v1:    claims +0/-0 (~1, =14) · abstract changed
```

## What the server does for you

On `POST /submissions` with `previous_version` set, the server (RRP-0017):

1. **Validates** the new CIR against `cir.schema.json`.
2. **Computes a `revision_diff`** between your v1 and v2 CIRs — claims matched on stable `local_id`, statement + proof shown as word-level hunks. This is returned inline in the response and cached for `GET /papers/{v2}/diff?from=<v1>`.
3. **Synthesises a `revision_summary` annotation** on v2 from your `--revision-summary` text. Authors can supersede this later with structured highlights if they want.
4. **Inherits the `id_slug`** from v1 — so `rrxiv:2605.00001` keeps pointing at "the paper" (latest version by default on the web client; explicit version pins via the diff page).

Both versions remain readable. v1's `claim_id`s remain valid forever; external citations don't break.

## Dry-run first

```bash
./scripts/submit.sh --dry-run --revision-summary "test run"
```

Returns the would-be paper_id, the computed diff, and validation result. Nothing is persisted. Idempotent: run a dozen dry-runs while iterating; the real submission still gets a fresh ID.

## When to publish v2 vs. an annotation

| Situation | Path |
|---|---|
| Discovered a critical error in a proof; corrected proof + statement | **v2**. The original claim_id is preserved in v1; v2 carries the corrected version. |
| Want to retract a single claim without changing the rest | **`claim_retraction` annotation** (RRP-0020) — fast path, no v2 needed. Reversible. |
| Typo, missing citation, broken figure path | **`erratum` annotation** — lighter weight than a revision. |
| Want to add new claims that extend the existing argument | **v2** if the new claims live in the same logical structure; or a **separate paper that `extends`** the existing one if it stands alone. |
| Want to publish updated experimental code without reanalysing | **`code_link` annotation**. |

## Writing a good `revision_summary`

The summary lands as an annotation pinned to the top of the v2 paper's discussion section. Aim for: one paragraph, plain prose, list the claim local_ids that changed and why. Skip the implementation details — readers can read the diff for those.

Example:

> v2 fixes an off-by-one in the bound on Claim 4 (the original proof miscounted the diagonal of the alternating sum). Adds Claim 5 + Claim 6 about pentagonal numbers as a corollary, plus a counter-example showing the bound is tight. The abstract was updated to reflect the new scope.

## Re-using the same git history

The paper template's CI workflow attaches built artefacts to each git tag (`v1`, `v2`, …). The canonical-instance ingestion happens via `./scripts/submit.sh` — which is independent of GitHub Releases but typically run after the tag is published so the source bundle hash matches the public release.

There is **no auto-discovery**: the canonical instance does not watch your repo, tags, or GitHub Releases, and there is no manifest sweep. Its manifest (`rrxiv-instance/papers/manifest.json`) is only the *bootstrap seed corpus* — pre-built snapshots used to seed a fresh database — not a version-sync channel. Every revision reaches the live instance exactly one way: `./scripts/submit.sh` (i.e. `rrxiv submit --revision-of`), where the server assigns the new version and the `previous_version` lineage. This applies even to papers that are in the canonical seed manifest.

## Recovery: I submitted a bad v2

You cannot edit a submission; it's part of the protocol's immutability guarantee. Options:

- Fix the offending content and submit a v3 immediately. The diff between v2 and v3 will document the correction.
- Post an `erratum` annotation on v2 explaining the issue — keeps the audit trail intact.
- Post a `claim_retraction` (RRP-0020) on a specific claim if the rest of v2 is fine.

## See also

- [RRP-0016 — Submission request schema](https://github.com/random-walks/rrxiv/blob/main/proposals/0016-submission-request-schema.md)
- [RRP-0017 — Revision flow + semantic diff](https://github.com/random-walks/rrxiv/blob/main/proposals/0017-revision-flow-and-diff.md)
- [RRP-0020 — Author claim retraction](https://github.com/random-walks/rrxiv/blob/main/proposals/0020-author-claim-retraction.md)
- [`rrxiv-python` README — CLI usage](https://github.com/random-walks/rrxiv-python#cli)
