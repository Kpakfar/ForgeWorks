#!/usr/bin/env bash
# .claude/hooks/tree-claim.sh
#
# PreToolUse hook (wired in .claude/settings.json). ONE SESSION WRITES A TREE
# AT A TIME. The first session that writes claims the working tree; a second
# session opened in the same directory is BLOCKED (exit 2) on writes until it
# moves into its own worktree or takes the claim over.
#
# Why a hook and not a rule: "branch into your own worktree" as prose does not
# bind -- the second session has to remember it before its first write, every
# time. This makes the collision a wall you hit, with the way out in the
# message.
#
# A claim belongs to ONE working tree, and the tree is the one being written:
# the file's own tree for Edit / Write / NotebookEdit, the shell's directory
# for Bash. It is NOT $CLAUDE_PROJECT_DIR -- that stays on the checkout the
# session was launched from, so a session that moved into a worktree would
# still be judged against the checkout it left. Each worktree of this
# repository carries its own claim; a path outside the repository is not
# guarded at all.
#
# What it guards: Edit / Write / NotebookEdit always, and Bash only for git
# commands that move HEAD, the index, or a branch. Reads, tests, builds, and
# plain shell are never blocked, so a second session can still investigate.
# Like deps-guard, this is a speed bump, not a lock: a shell redirect or an
# in-place sed still writes. It catches the way agents actually edit.
#
# The claim is .claude/.tree-claim (gitignored). Every allowed write refreshes
# it, so a session that crashes or is closed goes stale on its own -- there is
# no cleanup step and nothing to prune. Staleness is TREE_CLAIM_TTL_MINUTES
# (default below); this hook owns that number.
#
# Exit code 2 blocks the tool call and feeds stderr back to the agent.

set -euo pipefail

TTL_MINUTES="${TREE_CLAIM_TTL_MINUTES:-30}"

input=$(cat)

read_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c '
import sys, json
path = sys.argv[1].lstrip(".").split(".")
d = json.load(sys.stdin)
for key in path:
    d = (d or {}).get(key)
print(d or "")' "$1" 2>/dev/null || true
  fi
}

sid=$(read_field '.session_id')
tool=$(read_field '.tool_name')

# No session id means no way to tell two sessions apart. Fail OPEN, and say so
# once rather than blocking every write.
if [ -z "${sid}" ]; then
  echo "tree-claim: no session id in the hook payload -- the tree is NOT claimed." >&2
  exit 0
fi

# Bash: guard only the commands that move git state. Everything else passes.
if [ "${tool}" = "Bash" ]; then
  cmd=$(read_field '.tool_input.command')
  # `git worktree add` is NOT here on purpose: it writes a DIFFERENT directory,
  # not this tree's files, HEAD, or index -- and it is the way out this hook
  # recommends, so blocking it would leave taking the tree over as the only move.
  git_verbs='commit|merge|rebase|reset|checkout|switch|restore|cherry-pick|revert|stash|apply|am|push|branch|tag|add|rm|mv|clean'
  printf '%s' "${cmd}" \
    | grep -Eq "(^|[[:space:];&|(])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+(${git_verbs})([[:space:]]|$)" \
    || exit 0
fi

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cwd=$(read_field '.cwd')

# The directory being written: the shell's for Bash, the file's otherwise.
if [ "${tool}" = "Bash" ]; then
  target="${cwd}"
else
  target=$(read_field '.tool_input.file_path')
  [ -n "${target}" ] || target=$(read_field '.tool_input.notebook_path')
  if [ -n "${target}" ]; then
    case "${target}" in /*) ;; *) target="${cwd:-${project}}/${target}" ;; esac
    target=$(dirname "${target}")
  fi
fi
# A new file may sit in a directory that does not exist yet.
while [ -n "${target}" ] && [ "${target}" != "/" ] && [ ! -d "${target}" ]; do
  target=$(dirname "${target}")
done

# The repository a directory belongs to (shared by all of its worktrees).
repo_of() {
  (cd "$1" 2>/dev/null && cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd -P) || true
}

root="${project}"
project_repo=$(repo_of "${project}")
if [ -n "${target}" ] && [ -n "${project_repo}" ]; then
  # Outside this repository (a scratch dir, another repo): not this tree.
  [ "$(repo_of "${target}")" = "${project_repo}" ] || exit 0
  root=$(git -C "${target}" rev-parse --show-toplevel 2>/dev/null || echo "${project}")
fi
claim="${root}/.claude/.tree-claim"

write_claim() {
  branch=$(git -C "${root}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  mkdir -p "${root}/.claude"
  tmp="${claim}.$$"
  { printf '%s\n' "${sid}"
    date '+%Y-%m-%d %H:%M:%S'
    printf '%s\n' "${branch}"
  } > "${tmp}"
  mv -f "${tmp}" "${claim}"
}

# Unclaimed -> claim it.
[ -f "${claim}" ] || { write_claim; exit 0; }

owner=$(head -n 1 "${claim}" 2>/dev/null || true)

# Mine -> refresh the heartbeat and pass.
[ "${owner}" = "${sid}" ] && { write_claim; exit 0; }

# Held by a session that has not written in TTL_MINUTES -> take it over.
if [ -n "$(find "${claim}" -mmin "+${TTL_MINUTES}" 2>/dev/null)" ]; then
  echo "tree-claim: claim from session ${owner:0:8} is stale (>${TTL_MINUTES}m) -- taking the tree." >&2
  write_claim
  exit 0
fi

since=$(sed -n '2p' "${claim}" 2>/dev/null || true)
onbranch=$(sed -n '3p' "${claim}" 2>/dev/null || true)
cat >&2 <<MSG
BLOCKED: another session is writing this tree.

  session ${owner:0:8} on ${onbranch:-unknown}, last write ${since:-unknown}

Two sessions in one directory overwrite each other's files, fight over the
index, and share one dev-server port. Do not ask the owner, and do not write
your files somewhere else to get around this. Move this session into its own
tree and carry on with the task there:

  1. Call the EnterWorktree tool. (No such tool: git worktree add
     .claude/worktrees/<name> -b <name> ${FACTORY_BASE:-main}
     then work in that directory. Branch from the base, never from here.)
  2. Redo the blocked write inside the new tree. Install dependencies first
     if the tree needs them.
  3. When the work is committed: bash scripts/land.sh

Only when you know the other session is finished or closed, take this tree
over instead: rm "${claim}", then retry.
MSG
exit 2
