#!/usr/bin/env bash
# Regression test for scripts/land.sh: a worktree branch lands on the base by
# rebase + fast-forward, a conflict stops in the worktree with the base
# untouched, and uncommitted work in the base checkout is never overwritten.
# Run from the repo root.
set -uo pipefail

L="$(pwd)/init-project/templates/core/scripts/land.sh"
rc=0
G() { git -c user.email=t@t -c user.name=t "$@"; }
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

repo=$(mktemp -d)
G -C "$repo" init -q -b main .
echo one > "$repo/a"; echo one > "$repo/b"
G -C "$repo" add -A; G -C "$repo" commit -qm init

tree() { G -C "$repo" worktree add -q "$repo/.wt/$1" -b "$1"; }
commit() { echo "$3" > "$repo/.wt/$1/$2"; G -C "$repo/.wt/$1" add -A; G -C "$repo/.wt/$1" commit -qm "$1: $2"; }
land() { (cd "$repo/.wt/$1" && bash "$L" >/dev/null 2>&1); }
expect() { # label wanted actual
  if [ "$2" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1: expected '$2', got '$3'"; rc=1; fi
}

# 1. Plain landing: the base checkout's files move with the branch.
tree w1; commit w1 a two
land w1; expect "lands a worktree branch" 0 $?
expect "base checkout received the change" two "$(cat "$repo/a")"

# 2. The base moved since the branch was cut: rebase, then fast-forward.
tree w2; tree w3
commit w2 b two; land w2
commit w3 c new
land w3; expect "lands after the base moved" 0 $?
expect "history stays linear (no merge commit)" 0 "$(G -C "$repo" rev-list --merges --count main)"
expect "both changes are on the base" "two new" "$(cat "$repo/b") $(cat "$repo/c")"

# 3. Uncommitted work in the worktree is refused.
tree w4; echo dirty > "$repo/.wt/w4/a"
land w4; expect "refuses uncommitted changes" 1 $?

# 4. A conflict stops in the worktree; the base is untouched.
tree w5; tree w6
commit w5 a five; land w5
commit w6 a six
before=$(G -C "$repo" rev-parse main)
land w6; expect "conflict fails the landing" 1 $?
expect "base untouched by the conflict" "$before" "$(G -C "$repo" rev-parse main)"
G -C "$repo/.wt/w6" rebase --abort

# 5. The base checkout has an uncommitted change to the same file: refused,
#    and that change survives.
tree w7; commit w7 b seven
echo mine > "$repo/b"
before=$(G -C "$repo" rev-parse main)
land w7; expect "refuses to overwrite the base checkout's work" 1 $?
expect "base checkout's uncommitted work survives" mine "$(cat "$repo/b")"
expect "base ref untouched" "$before" "$(G -C "$repo" rev-parse main)"
G -C "$repo" checkout -q -- b

# 6. An uncommitted change to a DIFFERENT file in the base checkout is fine.
echo mine > "$repo/c"
land w7; expect "lands beside unrelated uncommitted work" 0 $?
expect "unrelated uncommitted work survives" mine "$(cat "$repo/c")"
G -C "$repo" checkout -q -- c

# 7. The base is checked out nowhere: the ref still moves.
tree w8; commit w8 d eight
G -C "$repo" checkout -q --detach
land w8; expect "lands when no tree has the base checked out" 0 $?
expect "base ref moved" "$(G -C "$repo/.wt/w8" rev-parse HEAD)" "$(G -C "$repo" rev-parse main)"
G -C "$repo" checkout -q main

# 8. Run on the base itself: refused. Nothing to land: a clean exit.
(cd "$repo" && bash "$L" >/dev/null 2>&1); expect "refuses to run on the base branch" 1 $?
tree w9; land w9; expect "nothing to land exits clean" 0 $?

rm -rf "$repo"
[ "$rc" = 0 ] && echo "land: OK" || echo "land: FAILED"
exit "$rc"
