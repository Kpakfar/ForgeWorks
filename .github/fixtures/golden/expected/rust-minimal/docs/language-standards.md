# Language & tooling standards

Language- and tool-specific conventions for this project. Filled in by `/init-project` from your setup answers. Update this file whenever a tooling decision changes.

## Language

- **Language:** Rust
- **Version:** 1.96 (edition 2024; pinned by rust-toolchain.toml)

## Package management

- **Package manager:** cargo
- **Manifest file:** Cargo.toml
- **Install dependencies:** `cargo fetch`
- **Add a dependency:** `cargo add`

Never bypass the package manager. Never install globally.

## Quality-gate toolchain

The bundled command `bash scripts/qa.sh` **verifies only and changes no files**, so it is safe in CI. It chains the following, in order; each must pass for the gate to be green.

| Step | Tool | Command |
|---|---|---|
| Lint (check) | clippy | `cargo clippy --all-targets -- -D warnings` |
| Format (check) | rustfmt | `cargo fmt --check` |
| Type-check | cargo check | `cargo check` |
| Tests (unit + functional) | cargo test | `cargo test` |

To auto-repair formatting and safe lint issues locally, run `bash scripts/fix.sh` -- the mutating counterpart -- then review the diff and commit. Never run `fix` in CI or a review hook: the gate must verify, not repair.

The end-to-end (headless-browser) suite is **not** in the fast gate. It runs separately via `bash scripts/e2e.sh` in CI and pre-merge, so the inner TDD loop stays fast. e2e tests are marked `e2e` and live under `tests/e2e/`.

## Coding conventions

These are the conventions `@implementer` and `@code-reviewer` enforce alongside the language-agnostic rules in `AGENTS.md` `<architecture-discipline>`.

### Type annotations

- Statically typed; the compiler is the type checker (`cargo check`). Explicit types on public signatures; let inference handle locals. Prefer borrowed views (`&str`, `&[T]`) for parameters and owned types for returns.

### Imports

- `use` statements at the top, grouped stdlib / third-party / crate-local, blank-line separated (rustfmt keeps each group sorted). No wildcard imports outside preludes and test modules.

### Async / concurrency

- Add async (tokio) only when the project is genuinely concurrent (server, many parallel I/O calls); a CLI, batch job, or library stays synchronous -- do not add an async runtime for its own sake. When async, keep the whole I/O path async and never block the executor (no `std::thread::sleep` or sync file I/O inside it).

### Error handling

- Return `Result<T, E>` with a domain error enum (`thiserror` in libraries; `anyhow` acceptable at the application boundary). No `unwrap()`/`expect()` outside tests and provably-infallible spots; `?` for propagation; `panic!` only for unrecoverable invariants. Fail closed on safety/security.

### Config and secrets

- Read env at one boundary into a typed config struct; never hardcode keys/URLs/models. Secrets in `.env` (gitignored), never in source or Cargo.toml.

### Logging

- `tracing` (structured, with spans) for application logs -- not `println!`.

### Test layout and fixtures

- Unit tests live beside the code in `#[cfg(test)] mod tests` blocks; integration tests in `tests/`; both run in the fast gate via `cargo test`. `tests/e2e.rs` is `#[ignore]`-tagged, excluded from the fast gate, run via `scripts/e2e.sh` (`cargo test --test e2e -- --ignored`).
- Table-style cases via loops over input/expected pairs; inject fakes via traits you own; avoid mocking frameworks.

## Pre-commit hooks

- Not used. The Rust profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.

## Supply chain

New dependencies pass through the `deps-guard` PreToolUse hook (`.claude/hooks/deps-guard.sh`): it blocks installs of new/named packages until you confirm the package is real and established and will land in the committed lockfile, then re-run with `DEPS_VETTED=1` in front. Install from the lockfile only; no blind `latest`.

## CI

GitHub Actions runs the fast `bash scripts/qa.sh` gate plus a separate end-to-end job (`bash scripts/e2e.sh`). The shipped workflow triggers on **pull requests** and on **pushes to `main`** (see `.github/workflows/qa.yml`).

A red run does not block a merge by itself -- that requires **branch protection** on the repository (Settings -> Branches -> require the `QA` checks to pass). The template cannot configure that for you; enable it once the repo is on GitHub so a red CI actually blocks the merge.

---

*Last updated: 2026-07-12*
