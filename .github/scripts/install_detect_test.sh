#!/usr/bin/env bash
# install.sh must classify a directory correctly: bootstrap an empty folder or
# an unfinished bootstrap, upgrade a project ForgeWorks generated, and stop
# without writing anything in a project with its own agent files. curl and npx
# are stubbed, so this runs offline. Run from the repo root.
set -euo pipefail
root=$(pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
cat > "$tmp/bin/curl" <<'STUB'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
printf '# AGENTS.md (Bootstrap Mode)\n' > "$out"
STUB
cat > "$tmp/bin/npx" <<'STUB'
#!/usr/bin/env bash
for a in "$@"; do case "$a" in .claude/skills/*) mkdir -p "$a" ;; esac; done
STUB
chmod +x "$tmp/bin/curl" "$tmp/bin/npx"

run() { # run <dir> [ENV=val ...] -> prints the installer's output, never fails
  local dir="$1"; shift
  (cd "$dir" && env PATH="$tmp/bin:$PATH" "$@" bash "$root/bootstrap/install.sh" 2>&1) || true
}
expect() { # expect <label> <output> <pattern>
  echo "$2" | grep -q "$3" || { echo "install-detect: FAIL -- $1"; echo "$2"; exit 1; }
}

d="$tmp/empty"; mkdir "$d"
expect "empty folder bootstraps" "$(run "$d")" "Bootstrap kit installed"
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

echo "install-detect: OK"
