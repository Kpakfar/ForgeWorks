#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. cargo fmt --check  (formatting is correct, but do not rewrite)
#   2. cargo clippy       (lint, all targets; warnings are errors)
#   3. cargo check        (compile/borrow check without codegen)
#   4. cargo test         (unit + functional; e2e excluded -- e2e tests are
#                          `#[ignore]`-tagged in tests/e2e.rs, and cargo test
#                          skips ignored tests by default)
#
# Each step must pass for the script to succeed. Because qa makes NO changes, it
# is safe to run in CI: a formatting or lint problem fails the build instead of
# being silently repaired in the disposable checkout. To auto-fix locally, run
# `scripts/fix.sh`, then commit, then run qa.
#
# This is the gate the code-reviewer agent enforces on every cycle. The slower
# end-to-end suite runs separately via scripts/e2e.sh in CI.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> [1/4] cargo fmt (check only)"
cargo fmt --check

echo
echo "==> [2/4] cargo clippy (warnings are errors)"
cargo clippy --all-targets -- -D warnings

echo
echo "==> [3/4] cargo check"
cargo check

echo
echo "==> [4/4] cargo test (unit + functional; e2e excluded via #[ignore])"
cargo test

echo
echo "==> QA passed (no files changed)."
