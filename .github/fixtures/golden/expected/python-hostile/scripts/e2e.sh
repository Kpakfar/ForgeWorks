#!/usr/bin/env bash
# scripts/e2e.sh
#
# The slow gate: end-to-end tests, kept OUT of the inner-loop quality gate so
# the TDD cycle stays fast. Runs in CI and pre-merge.
#
# For a UI project this is the headless-browser suite (e.g. pytest-playwright);
# for an API-only project it is full request -> response -> persisted-state runs.
# e2e tests are marked `@pytest.mark.e2e` and live under tests/e2e/.
#
# Exits 0 when there are no e2e tests yet (pytest exit code 5), so the suite is
# green until the first e2e test is written.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> end-to-end tests (marker: e2e)"
set +e
uv run pytest -m e2e
code=$?
set -e

if [ "$code" -eq 5 ]; then
  echo "==> no e2e tests yet (exit 5 treated as pass)."
  exit 0
fi

exit "$code"
