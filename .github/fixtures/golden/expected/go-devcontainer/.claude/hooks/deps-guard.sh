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
# lockfile), put DEPS_VETTED=1 at the START of the (sub)command, e.g.:
#   DEPS_VETTED=1 uv add httpx
#
# Compound commands are checked PER SEGMENT (split on && / || / ;), so a vetted
# or allowed segment cannot launder an install later in the same line, and
# DEPS_VETTED=1 vets only the segment it prefixes.
#
# Exit code 2 blocks the tool call and feeds stderr back to the agent.

set -euo pipefail

input=$(cat)

# Extract the actual command field (not the whole JSON, so DEPS_VETTED or a
# package name elsewhere in the payload cannot flip the decision).
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
else
  # No JSON parser available, so the command cannot be inspected. Fail OPEN
  # (blocking every Bash call would brick the session) but say so.
  echo "deps-guard: neither jq nor python3 found -- supply-chain guard is NOT inspecting commands." >&2
  exit 0
fi

# Not a Bash command (no command field) -> nothing to guard.
[ -z "${cmd}" ] && exit 0

# Package token: flags may precede it; an optional quote may wrap it (so
# `npm install "evil"` cannot hide behind quoting -- quotes are also stripped
# from the matching copy below, this is belt-and-braces).
pkg='([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+[^-[:space:]]'
# Remote-execute forms (run arbitrary remote code): npx / bunx / uvx and
# pnpm|yarn dlx (flags such as -y / --yes / --from may precede the package),
# npm exec / npm x, uv tool install|run, yarn global add, `npm --prefix <dir>`
# when it is an install/add/exec (not e.g. `npm --prefix . test`), piping a
# download into a shell, and process-substituting a download into a shell.
remote_exec='(npx|bunx|uvx)([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+[^-[:space:]]|(pnpm|yarn)[[:space:]]+dlx([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+[^-[:space:]]|npm[[:space:]]+(exec|x)([[:space:]]|$)|npm[[:space:]]+--prefix[[:space:]]+[^[:space:]]+[[:space:]]+(install|add|i|exec|ci)|uv[[:space:]]+tool[[:space:]]+(install|run)|yarn[[:space:]]+global[[:space:]]+add|(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)|(ba|z|da)?sh[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(<[[:space:]]*)?<\((curl|wget)'
block_re="(npm|pnpm|yarn|bun)([[:space:]]+-{1,2}[^[:space:]]+)*[[:space:]]+(install|add|i)${pkg}|pip3?[[:space:]]+install${pkg}|pipx[[:space:]]+(install|run|inject)${pkg}|uv[[:space:]]+(add|pip[[:space:]]+install)${pkg}|poetry[[:space:]]+add${pkg}|cargo[[:space:]]+(add|install|update)|go[[:space:]]+(get|install)${pkg}|gem[[:space:]]+install${pkg}|brew[[:space:]]+install${pkg}|${remote_exec}"

# pip install whose every argument is a flag, -r/-c <local file>, -e <local
# path>, or `.` is a from-lock / editable install -> allow. Anchored to the
# segment end so `pip install -r requirements.txt evil-extra` does NOT slip
# through, and the -r/-e argument may not contain `:` so remote requirements
# (`-r https://...`) and VCS editables (`-e git+https://...`) stay blocked.
pip_allow='^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(uv[[:space:]]+|python3?[[:space:]]+-m[[:space:]]+)?pip3?[[:space:]]+install([[:space:]]+(-r|--requirement|-c|--constraint|-e|--editable)[[:space:]]+[^[:space:]:]+|[[:space:]]+-{1,2}[^[:space:]]+|[[:space:]]+\.)*[[:space:]]*$'

# Vetted segment: DEPS_VETTED=1 as a real env-assignment prefix (optionally
# after other VAR=val prefixes). Requires exactly `=1` (rejects `=0`) and
# rejects tricks like `echo DEPS_VETTED && npm install evil`. The prefix vets
# only the FIRST command of a pipeline; `| <install>` later is still checked.
vetted='^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*DEPS_VETTED=1[[:space:]]'

# Split on command separators (&& / || / ;) but NOT on single | -- pipelines
# stay whole so `curl ... | bash` is visible. The split is pure bash (no
# heredoc/herestring: those need a writable temp dir on some systems and a
# failure there would make the whole hook FAIL OPEN). Each segment is judged
# alone; noglob (set -f) keeps the unquoted expansion from globbing.
blocked=0
nl=$'\n'
seglist=${cmd//'&&'/$nl}
seglist=${seglist//'||'/$nl}
seglist=${seglist//';'/$nl}
set -f
IFS=$nl
for seg in $seglist; do
  [ -z "${seg//[[:space:]]/}" ] && continue
  # Strip quotes and backslashes on the matching copy only, so quoting tricks
  # ("evil", n\pm) cannot hide a package or command name.
  m=$(printf '%s' "$seg" | tr -d '"'"'"'\\')
  if printf '%s' "$seg" | grep -Eq "$vetted"; then
    # Vetted prefix covers only the first pipeline command -- check the rest.
    case "$m" in
      *\|*)
        rest=${m#*|}
        if printf '%s' "$rest" | grep -Eq "$block_re"; then blocked=1; break; fi ;;
    esac
    continue
  fi
  printf '%s' "$m" | grep -Eq "$pip_allow" && continue
  if printf '%s' "$m" | grep -Eq "$block_re"; then
    blocked=1
    break
  fi
done
unset IFS
set +f

if [ "$blocked" -eq 1 ]; then
  {
    echo "Supply-chain guard (best-effort): this command installs a new dependency or runs remote code."
    echo "Before it runs, confirm the package:"
    echo "  - is the real, established package (right author, age, downloads) -- not a hallucinated or typosquatted lookalike;"
    echo "  - is pinned and will land in the committed lockfile (no blind 'latest');"
    echo "  - is not brand new (prefer packages more than ~a week old)."
    echo "If verified, re-run with DEPS_VETTED=1 at the START of that segment, e.g.:  DEPS_VETTED=1 <command>"
    echo "(If this matched text inside a string or commit message, it is a false positive -- rephrase or vet it.)"
    echo "(A reminder, not a security boundary -- lockfile review + CI scanning are the real controls.)"
  } >&2
  exit 2
fi

exit 0
