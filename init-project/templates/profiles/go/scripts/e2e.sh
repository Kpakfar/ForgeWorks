#!/usr/bin/env bash
# scripts/e2e.sh
#
# The slow gate: end-to-end tests, kept OUT of the inner-loop quality gate so
# the TDD cycle stays fast. Runs in CI and pre-merge.
#
# Go e2e tests are guarded by the `e2e` build tag and live under tests/e2e/, so
# the fast `go test ./...` never sees them. For an API or CLI project this is the
# full request -> response -> persisted-state path; add a browser driver only if
# the project grows a UI surface.
#
# Stays green until the first e2e test is written: with the `e2e` tag and no test
# functions yet, `go test` simply reports no tests and exits 0.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> end-to-end tests (build tag: e2e)"
set +e
out=$(go test -tags e2e ./... 2>&1)
code=$?
set -e

echo "$out"

if [ "$code" -eq 0 ]; then
  if echo "$out" | grep -Eq "no tests to run|no test files"; then
    echo "==> no e2e tests yet (treated as pass)."
  fi
  exit 0
fi

exit "$code"
