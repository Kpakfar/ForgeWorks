#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. gofmt -l           (formatting is correct, but do not rewrite)
#   2. go vet ./...       (suspicious-construct check)
#   3. golangci-lint run  (lint; skipped with a warning if not installed)
#   4. go test ./...      (unit + functional; e2e excluded -- needs the `e2e` tag)
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

echo "==> [1/4] gofmt (check only)"
fmtout=$(gofmt -l .)
[ -z "$fmtout" ] || { echo "unformatted files:"; echo "$fmtout"; exit 1; }

echo
echo "==> [2/4] go vet"
go vet ./...

echo
echo "==> [3/4] golangci-lint run"
if command -v golangci-lint >/dev/null 2>&1; then
  golangci-lint run
else
  echo "golangci-lint not installed -- skipping (install: https://golangci-lint.run/)."
fi

echo
echo "==> [4/4] go test (unit + functional; e2e excluded)"
go test ./...

echo
echo "==> QA passed (no files changed)."
