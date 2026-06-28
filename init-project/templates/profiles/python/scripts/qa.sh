#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. ruff check        (lint, no auto-fix)
#   2. ruff format --check (formatting is correct, but do not rewrite)
#   3. mypy              (type check)
#   4. pytest            (unit + functional; e2e excluded via `-m "not e2e"`)
#
# Each step must pass for the script to succeed. Because qa makes NO changes, it
# is safe to run in CI: a formatting or lint problem fails the build instead of
# being silently repaired in the disposable checkout. To auto-fix locally, run
# `scripts/fix.sh` (or `uv run fix`), then commit, then run qa.
#
# This is the gate the code-reviewer agent enforces on every cycle. The slower
# end-to-end (headless-browser) suite runs separately via scripts/e2e.sh in CI.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> [1/4] ruff check"
uv run ruff check .

echo
echo "==> [2/4] ruff format --check"
uv run ruff format --check .

echo
echo "==> [3/4] mypy"
uv run mypy src/

echo
echo "==> [4/4] pytest (unit + functional; e2e excluded)"
uv run pytest -m "not e2e"

echo
echo "==> QA passed (no files changed)."
