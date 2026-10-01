#!/usr/bin/env bash
# Regression test for the tree-claim hook: assert it BLOCKS (exit 2) a second
# session's writes and ALLOWS (exit 0) the owner, reads, and a stale claim.
# Run from the repo root.
set -uo pipefail

H="$(pwd)/init-project/templates/core/.claude/hooks/tree-claim.sh"
rc=0

tree=$(mktemp -d)
mkdir -p "$tree/.claude"
git -C "$tree" init -q -b main .
git -C "$tree" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
export CLAUDE_PROJECT_DIR="$tree"

check() { # label expected payload
  local label="$1" want="$2" payload="$3" got
  printf '%s' "$payload" | bash "$H" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    echo "ok    $label (exit $got)"
  else
    echo "FAIL  $label: expected exit $want, got $got"
    rc=1
  fi
}

check "owner claims an unclaimed tree" 0 '{"session_id":"AAA","tool_name":"Edit","tool_input":{"file_path":"a"}}'
check "owner writes again"             0 '{"session_id":"AAA","tool_name":"Write","tool_input":{"file_path":"a"}}'
check "second session Edit blocked"    2 '{"session_id":"BBB","tool_name":"Edit","tool_input":{"file_path":"a"}}'
check "second session Write blocked"   2 '{"session_id":"BBB","tool_name":"Write","tool_input":{"file_path":"a"}}'
check "second session git commit"      2 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'
check "second session git -C add"      2 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"cd /x; git -C /r add ."}}'
check "second session reads allowed"   0 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"ls -la && git status && git log"}}'
check "second session git diff"        0 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"git diff --stat"}}'
check "second session test run"        0 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"npm test -- --watch=false"}}'
check "second session opens its own worktree" 0 '{"session_id":"BBB","tool_name":"Bash","tool_input":{"command":"git worktree add ../wt -b feat/x"}}'
check "no session id fails open"       0 '{"tool_name":"Edit","tool_input":{"file_path":"a"}}'

# The way out has to work. A session that moved into a worktree is judged
# against THAT tree's claim, though CLAUDE_PROJECT_DIR still names the checkout
# it was launched from. A path outside the repository is not guarded at all.
wt="$tree/.claude/worktrees/w1"
git -C "$tree" worktree add -q "$wt" -b w1
outside=$(mktemp -d)
check "second session Edit in its own worktree"  0 '{"session_id":"BBB","cwd":"'"$wt"'","tool_name":"Edit","tool_input":{"file_path":"'"$wt"'/a"}}'
check "second session new dir in its worktree"   0 '{"session_id":"BBB","cwd":"'"$wt"'","tool_name":"Write","tool_input":{"file_path":"'"$wt"'/new/dir/a"}}'
check "second session commit in its worktree"    0 '{"session_id":"BBB","cwd":"'"$wt"'","tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'
check "worktree session still blocked on primary" 2 '{"session_id":"BBB","cwd":"'"$wt"'","tool_name":"Edit","tool_input":{"file_path":"'"$tree"'/a"}}'
check "third session blocked in a claimed worktree" 2 '{"session_id":"CCC","cwd":"'"$wt"'","tool_name":"Edit","tool_input":{"file_path":"'"$wt"'/a"}}'
check "owner still owns the primary"             0 '{"session_id":"AAA","cwd":"'"$tree"'","tool_name":"Edit","tool_input":{"file_path":"'"$tree"'/a"}}'
check "write outside the repository not guarded" 0 '{"session_id":"BBB","cwd":"'"$tree"'","tool_name":"Write","tool_input":{"file_path":"'"$outside"'/a"}}'
[ ! -e "$outside/.claude" ] || { echo "FAIL  hook wrote a claim outside the repository"; rc=1; }
rm -rf "$outside"

# A claim nobody has refreshed for longer than the TTL is taken over, so a
# closed or crashed session never leaves the tree locked.
touch -d "2020-01-01" "$tree/.claude/.tree-claim" 2>/dev/null \
  || touch -t 202001010000 "$tree/.claude/.tree-claim"
check "stale claim taken over"         0 '{"session_id":"BBB","tool_name":"Edit","tool_input":{"file_path":"a"}}'
owner=$(head -n 1 "$tree/.claude/.tree-claim")
if [ "$owner" = "BBB" ]; then
  echo "ok    takeover rewrote the claim owner"
else
  echo "FAIL  takeover left owner as '$owner', expected BBB"
  rc=1
fi

rm -rf "$tree"
[ "$rc" = 0 ] && echo "tree-claim: OK" || echo "tree-claim: FAILED"
exit "$rc"
