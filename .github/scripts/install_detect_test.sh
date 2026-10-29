#!/usr/bin/env bash
# install.sh must classify a directory correctly: bootstrap an empty folder or
# an unfinished bootstrap, upgrade a project ForgeWorks generated, and stop
# without writing anything in a project with its own agent files. curl is
# stubbed, so this runs offline. Run from the repo root.
set -euo pipefail
root=$(pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
# curl serves a fake release archive on stdout; there is no npx at all, so a
# Node dependency creeping back into the installer fails this test.
mkdir -p "$tmp/archive/ForgeWorks-x/bootstrap" "$tmp/archive/ForgeWorks-x/init-project" \
  "$tmp/archive/ForgeWorks-x/upgrade-project"
printf '# AGENTS.md (Bootstrap Mode)\n' > "$tmp/archive/ForgeWorks-x/bootstrap/AGENTS.md"
echo skill > "$tmp/archive/ForgeWorks-x/init-project/SKILL.md"
echo skill > "$tmp/archive/ForgeWorks-x/upgrade-project/SKILL.md"
tar -czf "$tmp/archive.tgz" -C "$tmp/archive" ForgeWorks-x
cat > "$tmp/bin/curl" <<STUB
#!/usr/bin/env bash
cat "$tmp/archive.tgz"
STUB
chmod +x "$tmp/bin/curl"

run() { # run <dir> [ENV=val ...] -> prints the installer's output, never fails
  local dir="$1"; shift
  (cd "$dir" && env PATH="$tmp/bin:$PATH" "$@" bash "$root/bootstrap/install.sh" 2>&1) || true
}
expect() { # expect <label> <output> <pattern>
  echo "$2" | grep -q "$3" || { echo "install-detect: FAIL -- $1"; echo "$2"; exit 1; }
}

d="$tmp/empty"; mkdir "$d"
expect "empty folder bootstraps" "$(run "$d")" "Bootstrap kit installed"
[ -f "$d/.claude/skills/init-project/SKILL.md" ] && grep -q "Bootstrap Mode" "$d/AGENTS.md" \
  || { echo "install-detect: FAIL -- the kit did not land from the archive"; exit 1; }
expect "unfinished bootstrap bootstraps again" "$(run "$d")" "Bootstrap kit installed"

d="$tmp/generated"; mkdir "$d"
printf '<!-- FW-BLOCK: project v5.0.0 -->\n' > "$d/AGENTS.md"
expect "generated project upgrades" "$(run "$d")" "Upgrade kit installed"

d="$tmp/foreign"; mkdir "$d"
printf '# My own agent rules\n' > "$d/AGENTS.md"
expect "foreign AGENTS.md stops" "$(run "$d")" "Nothing was written"
[ ! -e "$d/.claude" ] || { echo "install-detect: FAIL -- a stopped run wrote files"; exit 1; }
expect "FORCE_UPGRADE overrides" "$(run "$d" FORCE_UPGRADE=1)" "Upgrade kit installed"

d="$tmp/own-agents"; mkdir -p "$d/.claude/agents"
expect "foreign .claude/agents stops" "$(run "$d")" "Nothing was written"
expect "FORCE_BOOTSTRAP overrides" "$(run "$d" FORCE_BOOTSTRAP=1)" "Bootstrap kit installed"

d="$tmp/own-claude"; mkdir "$d"; printf '# rules\n' > "$d/CLAUDE.md"
expect "foreign CLAUDE.md stops" "$(run "$d")" "Nothing was written"

d="$tmp/code"; mkdir -p "$d/src"; printf 'x\n' > "$d/src/app.py"; printf 'y\n' > "$d/pyproject.toml"
expect "an existing codebase stops" "$(run "$d")" "not an empty folder"
[ ! -e "$d/AGENTS.md" ] || { echo "install-detect: FAIL -- a stopped run wrote AGENTS.md"; exit 1; }
expect "FORCE_BOOTSTRAP overrides a non-empty folder" "$(run "$d" FORCE_BOOTSTRAP=1)" "Bootstrap kit installed"

d="$tmp/gh-clone"; mkdir -p "$d/.git" "$d/.idea" "$d/.vscode"; printf '# x\n' > "$d/README.md"; : > "$d/LICENSE"; : > "$d/.gitignore"
expect "a fresh gh repo clone with editor folders bootstraps" "$(run "$d")" "Bootstrap kit installed"

echo "install-detect: OK"
