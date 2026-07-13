#!/usr/bin/env bash
# scripts/qa.sh
#
# The FAST gate (inner loop) -- VERIFY ONLY, never mutates files. Runs in order:
#   1. line cap           (no file over 200 lines; see scripts/linecap.sh)
#   2. gofmt -l           (formatting is correct, but do not rewrite)
#   3. go vet ./...       (suspicious-construct check)
#   4. golangci-lint run  (lint; REQUIRED -- fails the gate if not installed)
#   5. go test ./...      (unit + functional; e2e excluded -- needs the `e2e` tag)
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

echo "==> [1/5] line cap (hard cap 200 lines per file)"
bash scripts/linecap.sh

echo
echo "==> [2/5] gofmt (check only)"
# .claude/skills holds installed skill templates -- not project code.
fmtout=$(gofmt -l . | grep -v '^\.claude/' || true)
[ -z "$fmtout" ] || { echo "unformatted files:"; echo "$fmtout"; exit 1; }

echo
echo "==> [3/5] go vet"
go vet ./...

echo
echo "==> [4/5] golangci-lint run"
if ! command -v golangci-lint >/dev/null 2>&1; then
  echo "ERROR: golangci-lint is not installed -- the lint gate cannot run." >&2
  echo "Install golangci-lint v2 (see https://golangci-lint.run/docs/welcome/install/)" >&2
  echo "or use the provided dev container, which installs it. Aborting." >&2
  exit 1
fi
golangci-lint run

echo
echo "==> [5/5] go test (unit + functional; e2e excluded)"
go test ./...

echo
echo "==> QA passed (no files changed)."
