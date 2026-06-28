#!/usr/bin/env bash
# scripts/fix.sh
#
# Local auto-repair -- the MUTATING counterpart to qa. Run this when qa reports a
# lint or formatting problem, then review the changes and commit them. Never run
# in CI or in a review hook: the gate must verify, not repair.
#
#   1. ruff check --fix  (apply safe lint fixes)
#   2. ruff format       (rewrite to canonical formatting)

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> ruff check --fix"
uv run ruff check . --fix

echo
echo "==> ruff format"
uv run ruff format .

echo
echo "==> Done. Review the changes (git diff), then run 'uv run qa' and commit."
