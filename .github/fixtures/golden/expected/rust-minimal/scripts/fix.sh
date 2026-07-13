#!/usr/bin/env bash
# scripts/fix.sh
#
# Local auto-repair -- the MUTATING counterpart to qa. Run this when qa reports a
# formatting or fixable lint problem, then review the changes and commit them.
# Never run in CI or in a review hook: the gate must verify, not repair.
#
#   1. cargo fmt          (rewrite to canonical formatting)
#   2. cargo clippy --fix (apply machine-applicable lint fixes; --allow-dirty /
#                          --allow-staged let it run on an uncommitted tree)

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> cargo fmt"
cargo fmt

echo
echo "==> cargo clippy --fix"
cargo clippy --fix --allow-dirty --allow-staged --all-targets

echo
echo "==> Done. Review the changes (git diff), then run 'bash scripts/qa.sh' and commit."
