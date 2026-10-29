#!/usr/bin/env bash
# The reviewer's Stop hook must gate the tree under review: a green main
# checkout must not pass a red worktree. QA here is "no file named RED", so
# the hook's verdict shows which tree it ran in. Run from the repo root.
set -euo pipefail
root=$(pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sed 's/{{QA_COMMAND}}/test ! -f RED/g' \
  "$root/init-project/templates/core/.claude/hooks/quality-gate.sh" > "$tmp/gate.sh"
git init -q -b main "$tmp/main"
git -C "$tmp/main" -c user.name=ci -c user.email=ci@example.com commit -q --allow-empty -m init
git -C "$tmp/main" worktree add -q "$tmp/main/.claude/worktrees/feat" -b feat
touch "$tmp/main/.claude/worktrees/feat/RED"
git init -q -b main "$tmp/other"; touch "$tmp/other/RED"

gate() { # gate <cwd> -> the hook's exit code
  printf '{"session_id":"s","cwd":"%s"}' "$1" \
    | CLAUDE_PROJECT_DIR="$tmp/main" bash "$tmp/gate.sh" >/dev/null 2>&1 && echo 0 || echo $?
}
fail() { echo "quality-gate: FAIL -- $1"; exit 1; }
[ "$(gate "$tmp/main")" = 0 ] || fail "a green main checkout did not pass"
[ "$(gate "$tmp/main/.claude/worktrees/feat")" = 2 ] || fail "a red worktree passed on main's green"
[ "$(gate "$tmp/main/.claude/worktrees/feat/.")" = 2 ] || fail "a subfolder of the red worktree passed"
[ "$(gate "$tmp/other")" = 0 ] || fail "a cwd in another repository was trusted"
[ "$(printf 'not json' | CLAUDE_PROJECT_DIR="$tmp/main" bash "$tmp/gate.sh" >/dev/null 2>&1 && echo 0 || echo $?)" = 0 ] \
  || fail "a payload without cwd did not fall back to the project"
echo "quality-gate: OK"
