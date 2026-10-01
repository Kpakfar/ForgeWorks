#!/usr/bin/env bash
# factory doctor -- list and prune stale worktrees and merged branches, then
# run the skills doctor (one copy per skill name; no always-on injection).
# Set FACTORY_BASE to the base branch name (default: main).
# Safe by default: prunes only worktrees whose directory is gone and merged
# branches; anything with uncommitted or unmerged work is LISTED, not touched.
# Exit status is the skills doctor's: 1 when the instruction stack has a
# collision the owner must resolve, 0 otherwise.
set -euo pipefail

BASE="${FACTORY_BASE:-main}"
git rev-parse --verify --quiet "$BASE" >/dev/null || { echo "factory-doctor: base branch '$BASE' not found (set FACTORY_BASE)"; exit 1; }

echo "== worktrees =="
git worktree prune
# One line per tree: what removing it would lose. Listed, never removed -- a
# session may still be standing in it.
git worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r tree; do
  br=$(git -C "$tree" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "detached")
  ahead=$(git -C "$tree" rev-list --count "$BASE..HEAD" 2>/dev/null || echo "?")
  dirty=$(git -C "$tree" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$br" = "$BASE" ]; then state="the base"
  elif [ "$ahead" = "0" ] && [ "$dirty" = "0" ]; then state="nothing unlanded -- safe to remove"
  else state="${ahead} commit(s) not on $BASE, ${dirty} uncommitted file(s)"
  fi
  echo "  $tree [$br]: $state"
done
echo
echo "== merged branches (safe to delete) =="
git branch --merged "$BASE" | grep -vE '^\*|  '"$BASE"'$' || echo "  none"
echo
echo "== NOT merged (needs a human decision) =="
git branch --no-merged "$BASE" | grep -v '^\*' || echo "  none"
echo
echo "Delete a merged branch with: git branch -d <name>"
echo "Remove a finished worktree with: git worktree remove <path>"
echo
# The meter: is the factory serving the product or itself? Computed from git
# alone -- nothing to write, nothing to game. Print only, no threshold: the
# owner judges the number (a rising docs:code ratio is the poison alarm).
echo "== meter (last 100 commits / last 28 days) =="
total=$(git rev-list --count -100 HEAD)
docs=$(git log --format='%s' -100 | grep -cE '^(docs|chore\(docs\))' || true)
merges=$(git log --merges --since="28 days ago" --oneline | wc -l | tr -d ' ')
echo "  doc-maintenance commits: ${docs}/${total} (the product got the rest)"
echo "  merges in the last 28 days: ${merges}"
echo
# The instruction stack: the budget CI measures is repo files only; this is
# the rest of what a session actually starts with (and what collides in it).
python3 "$(dirname "$0")/skills_doctor.py" --root "$(git rev-parse --show-toplevel)"
