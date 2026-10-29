# Chunkline -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.

Primary user: A backend developer building document indexing who needs deterministic chunk boundaries. Problem: Ad-hoc chunkers produce different boundaries across runs and platforms, which invalidates cached embeddings and makes diffs noisy.
Today's alternative: hand-rolled splitters that drift between runs. Why this wins: determinism is the contract, verified by cross-platform tests

## The journey (end to end)

1. The developer adds the library and configures chunk size and overlap.
2. They feed it a text stream.
3. They receive deterministic chunks with stable ids that survive re-runs on unchanged input.

## Surfaces

- (no user-facing surfaces -- API/CLI product)

## v1 includes

- Deterministic size/overlap chunking over byte and char boundaries.
- Stable chunk ids derived from content.
- A benchmark harness for the throughput target.

## v1 excludes

- No tokenizer-aware chunking in the first iteration; bytes and characters only.
- No async API; the library is synchronous.

## Success looks like

- determinism -- byte-identical chunk ids across two runs and two platforms
- throughput -- at least 50MB/s on the reference corpus
