#!/usr/bin/env bash
# .claude/hooks/quality-gate.sh
#
# Triggered by the code-reviewer subagent on Stop (auto-converted to
# SubagentStop). Runs the bundled quality-gate command for this project.
#
# The exact command is set by /init-project from the language and tooling
# answers and is also documented in docs/language-standards.md.
#
# Exit code 2 blocks the subagent from completing (see
# https://code.claude.com/docs/en/hooks). Any other non-zero exit is logged
# but does NOT block, so we deliberately exit 2 on QA failure to gate
# APPROVE on a passing build.

set -euo pipefail

# Only exit 2 blocks the subagent; any other non-zero exit is logged and
# IGNORED by the hook runner. Without this trap, an infrastructure error (a
# failing cd, a missing tool outside the guarded `if`) would exit 1 and the
# review would complete with no gate at all -- fail CLOSED instead.
trap 'echo "FAILED: quality-gate hook errored before QA could complete." >&2; exit 2' ERR

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "==> Quality gate: running npm run qa"
echo

if ! npm run qa; then
  echo
  echo "FAILED: Quality gate did not pass." >&2
  echo "The code-reviewer subagent cannot complete until QA is green." >&2
  exit 2
fi

echo
echo "PASSED: Quality gate green."
