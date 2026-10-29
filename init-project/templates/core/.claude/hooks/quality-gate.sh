#!/usr/bin/env bash
# .claude/hooks/quality-gate.sh
#
# Triggered by the reviewer subagent on Stop (auto-converted to
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

# Gate the tree under review, not the launch checkout. $CLAUDE_PROJECT_DIR
# stays on the checkout the session started in, so a session that moved into
# its own worktree would get main's green. The hook payload's cwd follows the
# session; it is trusted only when it is a worktree of this same repository.
project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
input=$(cat 2>/dev/null || true)
cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  cwd=$(printf '%s' "$input" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("cwd") or "")' 2>/dev/null || true)
fi
tree="$project"
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  ours=$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
  theirs=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
  if [ -n "$top" ] && [ -n "$ours" ] && [ "$ours" = "$theirs" ]; then
    tree="$top"
  fi
fi
cd "$tree"

echo "==> Quality gate: running {{QA_COMMAND}} in $tree"
echo

if ! {{QA_COMMAND}}; then
  echo
  echo "FAILED: Quality gate did not pass." >&2
  echo "The reviewer subagent cannot complete until QA is green." >&2
  exit 2
fi

echo
echo "PASSED: Quality gate green."
