#!/usr/bin/env bash
# land -- put this worktree's branch on the base branch. One command, no merge
# commit, no pull request.
#
#   bash scripts/land.sh      # from inside a worktree, with the work committed
#
# Set FACTORY_BASE to the base branch name (default: main).
#
# It rebases this branch onto the base, then fast-forwards the base to it. A
# conflict therefore stops HERE, in the tree of the session that made the
# change, and never in the base checkout. The base checkout only ever receives
# a fast-forward, and git refuses that when it would overwrite an uncommitted
# change there -- so another session working on the base loses nothing.
#
# It does not push, and it does not remove this worktree: a session is still
# standing in it. Keep working and land again, or leave the tree (ExitWorktree,
# or `git worktree remove`). `bash scripts/factory_doctor.sh` lists the landed
# trees nobody removed.
set -euo pipefail

BASE="${FACTORY_BASE:-main}"
die() { echo "land: $*" >&2; exit 1; }

git rev-parse --show-toplevel >/dev/null 2>&1 || die "not inside a git working tree."
git rev-parse --verify --quiet "refs/heads/${BASE}" >/dev/null \
  || die "base branch '${BASE}' not found (set FACTORY_BASE)."
branch=$(git symbolic-ref --quiet --short HEAD) \
  || die "no branch checked out. A rebase in progress? Resolve it, run 'git rebase --continue', then land again."
[ "${branch}" != "${BASE}" ] \
  || die "this tree is on '${BASE}' itself. Land from a worktree branch; work committed on '${BASE}' is already there."
[ -z "$(git status --porcelain)" ] \
  || die "uncommitted changes. Commit them first; land moves commits only."

count=$(git rev-list --count "${BASE}..HEAD")
if [ "${count}" = "0" ]; then
  echo "land: nothing to land -- '${branch}' has no commit that '${BASE}' lacks."
  exit 0
fi

rebased=no
if ! git merge-base --is-ancestor "${BASE}" HEAD; then
  rebased=yes
  git rebase --quiet "${BASE}" || die "'${BASE}' moved and the rebase hit a conflict. Resolve it in this tree, run 'git rebase --continue', then land again. '${BASE}' is untouched."
fi

# The tree that has the base checked out, if any, must move with the branch.
base_tree=$(git worktree list --porcelain | awk -v ref="refs/heads/${BASE}" '
  /^worktree / { tree = substr($0, 10) }
  $1 == "branch" && $2 == ref { print tree; exit }')

if [ -n "${base_tree}" ]; then
  git -C "${base_tree}" merge --quiet --ff-only "${branch}" \
    || die "'${BASE}' is checked out at ${base_tree} and has an uncommitted change to a file this branch also changed. Commit it there, then land again. Nothing was lost; this branch is rebased and ready."
else
  git fetch --quiet . "${branch}:${BASE}" || die "could not fast-forward '${BASE}'."
fi

echo "land: ${count} commit(s) from '${branch}' are on '${BASE}'. Not pushed."
git log --oneline -n "${count}" | sed 's/^/  /'
if [ "${rebased}" = "yes" ]; then
  echo "land: '${BASE}' had moved, so the branch was rebased. Run the quality gate again before you push."
fi
