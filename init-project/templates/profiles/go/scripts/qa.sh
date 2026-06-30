#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. gofmt -l           (formatting is correct, but do not rewrite)
#   2. go vet ./...       (suspicious-construct check)
#   3. golangci-lint run  (lint; REQUIRED -- fails the gate if not installed)
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
if ! command -v golangci-lint >/dev/null 2>&1; then
  echo "ERROR: golangci-lint is not installed -- the lint gate cannot run." >&2
  echo "Install golangci-lint v2 (see https://golangci-lint.run/docs/welcome/install/)" >&2
  echo "or use the provided dev container, which installs it. Aborting." >&2
  exit 1
fi
golangci-lint run

echo
echo "==> [4/4] go test (unit + functional; e2e excluded)"
go test ./...

echo
echo "==> QA passed (no files changed)."
