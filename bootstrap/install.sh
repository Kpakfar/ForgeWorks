#!/usr/bin/env bash
# install.sh - Bootstrap a new project from this template.
#
# Usage (pinned to an immutable release tag -- recommended):
#   bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v1.0.0/bootstrap/install.sh)
#
# Everything this script fetches is pinned to the same ref (default: the release
# tag below), so the bootstrap is reproducible and cannot change under you when
# `main` moves. Override the ref for development with REF=... or BRANCH=...
# (e.g. BRANCH=main to test the latest unreleased state).
#
# This script:
#   1. Validates the environment (curl, git, npx).
#   2. Drops the bootstrap AGENTS.md into the current directory.
#   3. Installs the init-project skill (SKILL.md + templates/) into
#      .claude/skills/init-project/ using `npx degit`.
#   4. Prints next steps.
#
# Language-specific prerequisites (uv, pnpm, cargo, go, etc.) are NOT
# checked here. /init-project asks you the language and verifies its
# package manager once the choice is made.

set -euo pipefail

REPO="${REPO:-Kpakfar/ForgeWorks}"
# Pinned, immutable release ref. Overridable for development (BRANCH=main, etc.).
REF="${REF:-${BRANCH:-v1.0.0}}"
RAW="https://raw.githubusercontent.com/${REPO}/${REF}"

echo "==> Bootstrapping AI project from ${REPO} (ref: ${REF})"
echo

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
# A generated project has .claude/agents/, or a non-bootstrap AGENTS.md.
# A bootstrap-mode AGENTS.md still counts as "not yet initialized" -> bootstrap.
INITIALIZED=0
[[ -d ".claude/agents" ]] && INITIALIZED=1
if [[ -f "AGENTS.md" ]] && ! grep -q "Bootstrap Mode" AGENTS.md 2>/dev/null; then
  INITIALIZED=1
fi

if [[ "${INITIALIZED}" -eq 1 ]]; then
  # --- UPGRADE MODE ---
  echo "==> Existing generated project detected. Installing the upgrade skill."
  echo "    (Nothing here is overwritten; /upgrade-project reconciles non-destructively.)"
  mkdir -p .claude/skills
  npx --yes degit "${REPO}/upgrade-project#${REF}" .claude/skills/upgrade-project --force
  printf '%s\n' "${REF}" > .claude/.template-version
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
npx --yes degit "${REPO}/init-project#${REF}" .claude/skills/init-project --force
# Stamp the source ref so a future /upgrade-project knows where this project started.
printf '%s\n' "${REF}" > .claude/.template-version

# 3. Done.
cat <<'EOF'

==> Bootstrap kit installed.

Next steps:

  1. Open Claude Code in this directory:
       claude

  2. Install the supporting skills (REQUIRED):
       npx skills@latest add mattpocock/skills
     Pick at minimum: tdd, grill-me, to-prd, caveman, write-a-skill, handoff
     Use mattpocock/skills for the core loop (not the broader superpowers pack).
     'tdd' is the Red -> Green -> Refactor methodology; 'grill-me' powers the
     planning interview. The generated subagents pair with them.

  3. In Claude Code, run:
       /init-project
     (or just say: "bootstrap this project")

The init skill will interview you about scope and stack, then generate the full
structure including a .mcp.json with Context7, a GitHub Actions CI workflow,
a PR template, pre-commit config, and (for fully-supported languages) a working
venv or equivalent. Language-specific prerequisites (uv for Python, pnpm for
TypeScript, etc.) are checked by /init-project after you pick a language.

EOF
