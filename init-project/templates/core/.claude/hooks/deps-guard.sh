#!/usr/bin/env bash
# .claude/hooks/deps-guard.sh
#
# PreToolUse hook on Bash (wired in .claude/settings.json). A **best-effort**
# supply-chain guard: it parses the Bash command and blocks (exit 2) the common
# dependency-install / remote-execute commands until the package has been vetted.
#
# This is a speed bump, NOT a security boundary. It is a heuristic on a command
# string -- it does not catch every form (a script that installs, an editor tool
# writing a manifest, a novel package manager, plain `npx <pkg>`). The REAL
# controls are: committed lockfiles + reviewed dependency updates, and CI
# vulnerability scanning (npm audit, Dependabot). Treat this as a reminder.
#
# Lockfile / from-lock installs (npm ci, uv sync, pip install -r/-e, etc.) are NOT
# blocked: they add nothing new. To proceed past a block after vetting (real,
# established package; right author; not a hallucinated lookalike; lands in the
# lockfile), put DEPS_VETTED=1 at the START of the command, e.g.:
#   DEPS_VETTED=1 uv add httpx
#
# Exit code 2 blocks the tool call and feeds stderr back to the agent.

set -euo pipefail

input=$(cat)

# Extract the actual command field (not the whole JSON, so DEPS_VETTED or a
# package name elsewhere in the payload cannot flip the decision).
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
fi

# Not a Bash command (no command field) -> nothing to guard.
[ -z "${cmd}" ] && exit 0

# Vetted ONLY when DEPS_VETTED=1 is a real env-assignment prefix at the start of
# the command (optionally after other VAR=val prefixes). Requires exactly `=1`
# (rejects `=0`) and rejects tricks like `echo DEPS_VETTED && npm install evil`.
if printf '%s' "$cmd" | grep -Eq '^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*DEPS_VETTED=1[[:space:]]'; then
  exit 0
fi

# pip install -r/-e/. is a from-lock / editable install -> allow.
if printf '%s' "$cmd" | grep -Eq 'pip3?[[:space:]]+install([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+(-r|--requirement|-e|--editable|\.([[:space:]]|$))'; then
  exit 0
fi

# Block: installing a NEW/named package, or fetching/executing arbitrary remote
# code. Flags may appear before the package name. (Lockfile installs such as
# `npm ci`, `uv sync`, `pip install -r` do not match.)
pkg='([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+[^-[:space:]"'"'"']'
# Remote-execute forms (run an arbitrary remote package): npx / bunx / uvx,
# pnpm|yarn dlx, npm exec, and npm --prefix ... install.
remote_exec='(npx|bunx|uvx)[[:space:]]+[^-[:space:]]|(pnpm|yarn)[[:space:]]+dlx[[:space:]]+[^-[:space:]]|npm[[:space:]]+exec[[:space:]]|npm[[:space:]]+--prefix[[:space:]]'
if printf '%s' "$cmd" | grep -Eq \
  "(npm|pnpm|yarn|bun)([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+(install|add|i)${pkg}|pip3?[[:space:]]+install${pkg}|pipx[[:space:]]+(install|run|inject)${pkg}|uv[[:space:]]+(add|pip[[:space:]]+install)${pkg}|poetry[[:space:]]+add${pkg}|cargo[[:space:]]+(add|install|update)|go[[:space:]]+(get|install)${pkg}|gem[[:space:]]+install${pkg}|${remote_exec}"; then
  {
    echo "Supply-chain guard (best-effort): this command installs a new dependency or runs remote code."
    echo "Before it runs, confirm the package:"
    echo "  - is the real, established package (right author, age, downloads) -- not a hallucinated or typosquatted lookalike;"
    echo "  - is pinned and will land in the committed lockfile (no blind 'latest');"
    echo "  - is not brand new (prefer packages more than ~a week old)."
    echo "If verified, re-run with DEPS_VETTED=1 at the START, e.g.:  DEPS_VETTED=1 <command>"
    echo "(A reminder, not a security boundary -- lockfile review + CI scanning are the real controls.)"
  } >&2
  exit 2
fi

exit 0
