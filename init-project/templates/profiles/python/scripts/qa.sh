#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. line cap          (no file over 200 lines; see scripts/linecap.sh)
#   2. ruff check        (lint, no auto-fix)
#   3. ruff format --check (formatting is correct, but do not rewrite)
#   4. mypy              (type check)
#   5. pytest            (unit + functional; e2e excluded via `-m "not e2e"`)
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

echo "==> [1/5] line cap (hard cap 200 lines per file)"
bash scripts/linecap.sh

echo
echo "==> [2/5] ruff check"
uv run ruff check .

echo
echo "==> [3/5] ruff format --check"
uv run ruff format --check .

echo
echo "==> [4/5] mypy"
uv run mypy src/

echo
echo "==> [5/5] pytest (unit + functional; e2e excluded)"
uv run pytest -m "not e2e"

echo
echo "==> QA passed (no files changed)."
