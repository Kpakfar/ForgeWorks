#!/usr/bin/env bash
# scripts/fix.sh
#
# Local auto-repair -- the MUTATING counterpart to qa. Run this when qa reports a
# formatting problem, then review the changes and commit them. Never run in CI or
# in a review hook: the gate must verify, not repair.
#
#   1. gofmt -w     (rewrite to canonical formatting)
#   2. goimports -w (group and prune imports; skipped if not installed)

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> gofmt -w"
gofmt -w .

echo
echo "==> goimports -w"
if command -v goimports >/dev/null 2>&1; then
  goimports -w .
else
  echo "goimports not installed -- skipping (install: golang.org/x/tools/cmd/goimports)."
fi

echo
echo "==> Done. Review the changes (git diff), then run 'bash scripts/qa.sh' and commit."
