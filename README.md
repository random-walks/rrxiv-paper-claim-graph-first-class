# The claim graph as a first-class artifact

A short argumentative paper making the case for addressing scholarly knowledge at the level of individual claims rather than whole papers — a demonstration paper in the [rrxiv](https://rrxiv.com) reference corpus.

**Read the published paper:** [rrxiv.com/papers/rrxiv:2605.00002](https://rrxiv.com/papers/rrxiv:2605.00002)

## What this demonstrates

A short argumentative paper making the case for addressing scholarly knowledge at the level of individual claims rather than whole papers. Seven claims linked by explicit support edges — the simplest shape a paper takes in this corpus, and a good first example to read.

## Build it locally

This repo was created from the [rrxiv-paper-template](https://github.com/random-walks/rrxiv-paper-template).

```bash
./scripts/build.sh          # tectonic → build/main.pdf
./scripts/extract-cir.sh    # rrxiv parse → build/main.cir.json
./scripts/verify.sh         # validate the CIR against the rrxiv schema
```

Install the `rrxiv` CLI used by these scripts:

```bash
pip install rrxiv
```

## License

Dual-licensed, matching the rest of the corpus:

- **Content** — the paper text and figures in `paper/`, plus `rrxiv-meta.json`, under [CC-BY-4.0](./LICENSE-CONTENT).
- **Code** — the `scripts/` and CI under [MIT](./LICENSE-CODE).
