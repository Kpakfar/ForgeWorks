#!/usr/bin/env bash
# scripts/e2e.sh
#
# The slow gate: end-to-end tests, kept OUT of the inner-loop quality gate so
# the TDD cycle stays fast. Runs in CI and pre-merge.
#
# Rust e2e tests live in tests/e2e.rs and are `#[ignore]`-tagged, so the fast
# `cargo test` (scripts/qa.sh) compiles but never runs them. Here they run via
# libtest's `--ignored` filter. For an API or CLI project this is the full
# request -> response -> persisted-state path; add a browser driver only if the
# project grows a UI surface.
#
# Stays green until real e2e tests exist: with the `--ignored` filter and no
# matching tests, cargo test reports 0 tests run and exits 0.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f tests/e2e.rs ]; then
  echo "==> tests/e2e.rs not found -- no e2e suite yet (treated as pass)."
  exit 0
fi

echo "==> end-to-end tests (tests/e2e.rs, #[ignore]-tagged)"
cargo test --test e2e -- --ignored
