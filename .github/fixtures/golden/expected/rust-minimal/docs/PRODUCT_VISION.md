# Product Vision: Chunkline

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **A backend developer building document indexing who needs deterministic chunk boundaries.**
who **needs deterministic chunk boundaries**,
Chunkline is a **text chunking library**
that **chunks that never move unless the text does**.
Unlike **hand-rolled splitters that drift between runs**,
we **determinism is the contract, verified by cross-platform tests**.

## 5W answers

- **Who:** A backend developer building document indexing who needs deterministic chunk boundaries.
- **What:** A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.
- **Why:** Ad-hoc chunkers produce different boundaries across runs and platforms, which invalidates cached embeddings and makes diffs noisy.
- **When:** none set
- **Where:** Published as a crate on crates.io; consumed as a library.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Deterministic size/overlap chunking over byte and char boundaries.
- Stable chunk ids derived from content.
- A benchmark harness for the throughput target.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No tokenizer-aware chunking in the first iteration; bytes and characters only.
- No async API; the library is synchronous.

## Business goals

Outcome + metric + target. Cap at three.

- determinism -- byte-identical chunk ids across two runs and two platforms
- throughput -- at least 50MB/s on the reference corpus

## Success looks like

> Chunking the same 100MB corpus twice yields byte-identical chunk sets and ids on two different machines.

---

*Last updated: 2026-07-12*
