#!/usr/bin/env bash
# .claude/hooks/deps-guard.sh
#
# PreToolUse hook on Bash (wired in .claude/settings.json). Supply-chain guard:
# it intercepts dependency-install/add commands across common ecosystems and
# blocks them (exit 2) until the package has been vetted. This is deterministic
# on purpose -- per the security rule, supply-chain safety belongs in a hook,
# not in a prompt asking the agent to be careful.
#
# Scope and limits (be honest about them):
#   - It inspects Bash commands only. It does NOT intercept direct edits to a
#     manifest/lockfile made through file-editing tools -- guard those in review.
#   - Lockfile installs (npm ci, uv sync, pip install -r/-e, etc.) are allowed:
#     they add nothing new. Commands that pull a NEW named package are blocked,
#     including ones where flags come before the package name
#     (npm install --save x, pnpm add -D x, uv add --dev x, pip install -U x).
#
# To proceed after vetting (real, established package; right author; not a
# hallucinated lookalike; lands in the lockfile), re-run with DEPS_VETTED=1 in
# front, e.g.  DEPS_VETTED=1 uv add httpx
#
# Exit code 2 blocks the tool call and feeds stderr back to the agent.

set -euo pipefail

input=$(cat)

# Already vetted by the caller -> allow.
if printf '%s' "$input" | grep -q 'DEPS_VETTED'; then
  exit 0
fi

# Explicit lockfile / install-from-source forms -> allow (they add nothing new).
# (npm ci; pnpm/yarn/bun install with no package; uv sync; uv pip sync;
#  pip install -r/-e/.; poetry/cargo/go/bundle install-from-lock.)
if printf '%s' "$input" | grep -Eq \
  '(npm[[:space:]]+ci|(pnpm|yarn|bun)[[:space:]]+install([[:space:]]+-{1,2}[^[:space:]]+)*([[:space:]]|"|$)|uv[[:space:]]+sync|uv[[:space:]]+pip[[:space:]]+sync|pip3?[[:space:]]+install([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+(-r|--requirement|-e|--editable|\.)|poetry[[:space:]]+install|cargo[[:space:]]+(build|fetch|update)|go[[:space:]]+mod[[:space:]]+download|bundle[[:space:]]+install)'; then
  exit 0
fi

# A command that pulls a NEW or NAMED package. The package name may be preceded
# by any number of flag tokens (-D, --save, --save-dev, -U, --upgrade, ...),
# then a bare (non-flag) token must follow.
flags='([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+[^-[:space:]"]'
if printf '%s' "$input" | grep -Eq \
  "(npm|pnpm|yarn|bun)[[:space:]]+(install|add|i)${flags}|pip3?[[:space:]]+install${flags}|uv[[:space:]]+(add|pip[[:space:]]+install)${flags}|poetry[[:space:]]+add${flags}|cargo[[:space:]]+add${flags}|go[[:space:]]+get${flags}|gem[[:space:]]+install${flags}"; then
  {
    echo "Supply-chain guard: this command installs a new dependency."
    echo "Before it runs, confirm the package:"
    echo "  - is the real, established package (right author, age, downloads) -- not a hallucinated or typosquatted lookalike;"
    echo "  - is pinned and will land in the committed lockfile (no blind 'latest');"
    echo "  - is not brand new (prefer packages more than ~a week old)."
    echo "If verified, re-run with DEPS_VETTED=1 in front, e.g.:  DEPS_VETTED=1 <command>"
  } >&2
  exit 2
fi

exit 0
