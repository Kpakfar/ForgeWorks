# Requirements: Chunkline

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.

## Why

Ad-hoc chunkers produce different boundaries across runs and platforms, which invalidates cached embeddings and makes diffs noisy.

## Who

**Primary user:** A backend developer building document indexing who needs deterministic chunk boundaries.

Other potential users (deferred to later iterations):
- none identified yet

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. The developer adds the library and configures chunk size and overlap.
2. They feed it a text stream.
3. They receive deterministic chunks with stable ids that survive re-runs on unchanged input.

**Success looks like:** Chunking the same 100MB corpus twice yields byte-identical chunk sets and ids on two different machines.

**Riskiest assumption** (test this first): Deterministic boundary selection can stay fast enough (50MB/s) without unsafe code.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** Chunking identical input twice yields identical chunk ids and boundaries.
- [ ] **REQ-AC2:** Overlap configuration is honored exactly at every boundary.
- [ ] **REQ-AC3:** A file smaller than one chunk yields exactly one chunk with a stable id.

## Stack

- **Language:** Rust 1.96 (edition 2024; pinned by rust-toolchain.toml)
- **Package manager:** cargo
- **Quality-gate command:** bash scripts/qa.sh
- **Test runner:** cargo test
- **Lint / format / type-check tools:** clippy / rustfmt / cargo check
- **Frontend:** no
- **Backend framework:** none (CLI/library)
- **Database / persistence:** none
- **Vector store:** none
- **LLM provider:** none
- **Embeddings model:** none
- **Dev container:** no
- **Deployment target:** Published as a crate on crates.io; consumed as a library.
- **Scale expectations (first iteration):** Library consumers processing files up to a few GB.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- none
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): no
- **Holds private data** (user records, secrets, anything non-public): no
- **Acts on the outside world** (sends, writes externally, side-effecting tools): no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No tokenizer-aware chunking in the first iteration; bytes and characters only.
- No async API; the library is synchronous.

## Constraints

- Time: Side project, one evening a week.
- Cost: None; pure open-source library.
- Data: Test corpora from public-domain texts only.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
