#!/usr/bin/env bash
# install.sh - Bootstrap a new project from this template.
#
# Usage (pinned to a versioned release tag -- recommended):
#   bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v2.2.0/bootstrap/install.sh)
#
# The template files this script fetches are pinned to one ref (default: the
# release tag below), so they do not change under you when `main` moves. (Runtime
# inputs -- skills@latest, the MCP package -- are not fully reproducible
# yet; see docs/ROADMAP.md.) Override the ref for development with REF=... or
# BRANCH=... (e.g. BRANCH=main to test the latest unreleased state).
#
# This script:
#   1. Validates the environment (curl, git, npx).
#   2. Drops the bootstrap AGENTS.md into the current directory.
#   3. Installs the init-project skill (SKILL.md + templates/) into
#      .claude/skills/init-project/ using `npx degit` (pinned version).
#   4. Prints next steps.
#
# The whole body runs inside main(), called on the last line, so a truncated
# download executes nothing.
#
# Language-specific prerequisites (uv, npm, go, cargo, etc.) are NOT
# checked here. /init-project asks you the language and verifies its
# package manager once the choice is made.

set -euo pipefail

main() {

REPO="${REPO:-Kpakfar/ForgeWorks}"
# Pinned, versioned release ref. Overridable for development (BRANCH=main, etc.).
REF="${REF:-${BRANCH:-v2.2.0}}"
RAW="https://raw.githubusercontent.com/${REPO}/${REF}"
# The tool that fetches the skill folders. Pinned so the installer's own supply
# chain does not float on npm's `latest`.
DEGIT="degit@2.8.4"

echo "==> Bootstrapping AI project from ${REPO} (ref: ${REF})"
echo

trap 'echo "ERROR: install did not complete -- this directory may be half-bootstrapped. Re-run after fixing the cause." >&2' ERR

# Required generic tools (both bootstrap and upgrade use these).
MISSING=()
command -v curl >/dev/null 2>&1 || MISSING+=("curl")
command -v npx >/dev/null 2>&1 || MISSING+=("npx (install Node.js: https://nodejs.org/)")
command -v git >/dev/null 2>&1 || MISSING+=("git")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "ERROR: Required generic tools are missing:" >&2
  for tool in "${MISSING[@]}"; do echo "  - $tool" >&2; done
  echo >&2
  echo "Install the missing tools, then re-run." >&2
  exit 1
fi

# Detect whether this is already a GENERATED project (vs empty / bootstrap state).
# Strongest signal: the version stamp a previous bootstrap wrote. Heuristics
# (.claude/agents/, a non-bootstrap AGENTS.md) can misfire on a repo with its
# own hand-made agents -- override with FORCE_BOOTSTRAP=1 if that is your case.
INITIALIZED=0
REASON=""
if [[ -f ".claude/.template-version" ]]; then
  INITIALIZED=1; REASON=".claude/.template-version exists"
elif [[ -d ".claude/agents" ]]; then
  INITIALIZED=1; REASON=".claude/agents/ exists"
elif [[ -f "AGENTS.md" ]] && ! grep -q "Bootstrap Mode" AGENTS.md 2>/dev/null; then
  # A bootstrap-mode AGENTS.md still counts as "not yet initialized" -> bootstrap.
  INITIALIZED=1; REASON="AGENTS.md is not the bootstrap-mode one"
fi
if [[ "${FORCE_BOOTSTRAP:-0}" == "1" ]]; then
  INITIALIZED=0
fi

if [[ "${INITIALIZED}" -eq 1 ]]; then
  # --- UPGRADE MODE ---
  echo "==> Existing generated project detected (${REASON}). Installing the upgrade skill."
  echo "    (Wrong guess? Re-run with FORCE_BOOTSTRAP=1 to bootstrap anyway.)"
  echo "    (Nothing here is overwritten; /upgrade-project reconciles non-destructively.)"
  mkdir -p .claude/skills
  npx --yes "${DEGIT}" "${REPO}/upgrade-project#${REF}" .claude/skills/upgrade-project --force
  # Do NOT stamp the version here: the existing `.claude/.template-version` is the
  # project's "from" version. /upgrade-project reads it, then writes the new
  # version only AFTER a successful upgrade. Stamping on kit install would destroy
  # the from->to provenance and contradict "nothing here is overwritten".
  cat <<'EOF'

==> Upgrade kit installed.

Next steps:

  1. Commit or stash any work in progress, then open Claude Code:
       claude

  2. In Claude Code, run:
       /upgrade-project
     (or say: "upgrade this project to the new template")

The upgrade skill reconciles your project against the current template:
it copies new always-on files that are missing, grafts new AGENTS.md rule
blocks and subagent sections into your existing files WITHOUT overwriting your
content, applies the language tooling delta, and reports what still needs a
manual look. It is non-destructive and safe to run more than once.

EOF
  exit 0
fi

# --- BOOTSTRAP MODE (empty directory) ---

# 1. Drop the bootstrap AGENTS.md.
echo "==> Installing bootstrap AGENTS.md"
curl -fsSL "${RAW}/bootstrap/AGENTS.md" -o AGENTS.md

# 2. Install the init-project skill (SKILL.md + templates/).
echo "==> Installing init-project skill into .claude/skills/init-project/"
mkdir -p .claude/skills
npx --yes "${DEGIT}" "${REPO}/init-project#${REF}" .claude/skills/init-project --force
# Stamp the source ref so a future /upgrade-project knows where this project started.
printf '%s\n' "${REF}" > .claude/.template-version

# 3. Done.
cat <<'EOF'

==> Bootstrap kit installed.

Next steps:

  1. Open Claude Code in this directory:
       claude

  2. In Claude Code, run:
       /init-project
     (or just say: "bootstrap this project")

/init-project installs the supporting skills (tdd, grill-me, ... from
mattpocock/skills), interviews you about scope and stack, then generates the full
project for your chosen language (Python, TypeScript, Go, or Rust): AGENTS.md, a .mcp.json
with Context7, CI, a PR template, and a green-on-first-run scaffold. It checks the
language's package manager (uv / npm / go) after you pick.

EOF

}

main "$@"
