#!/usr/bin/env bash
# Regression test for scripts/skills_doctor.py: rebuild the 2026-08-22 field
# condition in a fake HOME (one skill name from two sources + a plugin that
# injects a SessionStart hook) and assert it FAILS; assert a symlinked copy is
# NOT a duplicate and a clean machine passes. Run from the repo root.
set -uo pipefail

DOCTOR="$(pwd)/init-project/templates/core/scripts/skills_doctor.py"
rc=0
fail() { echo "FAIL: $*"; rc=1; }

mk_home() {  # $1 = home dir; lays down a project + personal skill set
  mkdir -p "$1/.agents/skills/tdd" "$1/.agents/skills/grill-me" "$1/.claude/skills"
  echo "# tdd" > "$1/.agents/skills/tdd/SKILL.md"
  echo "# grill" > "$1/.agents/skills/grill-me/SKILL.md"
  ln -s ../../.agents/skills/tdd "$1/.claude/skills/tdd"        # a link, not a copy
  ln -s ../../.agents/skills/grill-me "$1/.claude/skills/grill-me"
}
mk_project() {
  mkdir -p "$1/.claude/skills/iteration"
  echo "# iteration" > "$1/.claude/skills/iteration/SKILL.md"
  printf 'agents\n' > "$1/AGENTS.md"
}

# --- 1. clean machine: symlinked upstream pair, project skills, no plugins ---
home=$(mktemp -d); proj=$(mktemp -d); mk_home "$home"; mk_project "$proj"
out=$(HOME="$home" python3 "$DOCTOR" --root "$proj" 2>&1); code=$?
[ "$code" -eq 0 ] || fail "clean machine should pass, got exit $code: $out"
echo "$out" | grep -q 'installed 2x' && fail "a symlink was counted as a second copy: $out"

# --- 2. the field condition: plugin copies + SessionStart injection ---
home=$(mktemp -d); proj=$(mktemp -d); mk_home "$home"; mk_project "$proj"
pack="$home/.claude/plugins/cache/m/pack/1.0.0"
sp="$home/.claude/plugins/cache/m/sp/1.0.0"
mkdir -p "$pack/skills/engineering/tdd" "$sp/skills/test-driven-development" \
         "$sp/skills/brainstorming" "$sp/hooks" "$home/.claude/plugins"
echo "# plugin tdd" > "$pack/skills/engineering/tdd/SKILL.md"
echo "# sp tdd" > "$sp/skills/test-driven-development/SKILL.md"
echo "# brainstorm" > "$sp/skills/brainstorming/SKILL.md"
echo '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[]}]}}' > "$sp/hooks/hooks.json"
cat > "$home/.claude/plugins/installed_plugins.json" <<EOF
{"version":2,"plugins":{
 "pack@m":[{"scope":"user","installPath":"$pack"}],
 "sp@m":[{"scope":"user","installPath":"$sp"}],
 "off@m":[{"scope":"user","installPath":"$pack"}]}}
EOF
echo '{"enabledPlugins":{"off@m":false}}' > "$home/.claude/settings.json"
out=$(HOME="$home" python3 "$DOCTOR" --root "$proj" 2>&1); code=$?
[ "$code" -eq 1 ] || fail "field condition should exit 1, got $code: $out"
echo "$out" | grep -q 'FAIL  `tdd` installed 2x' || fail "missing tdd duplicate finding: $out"
echo "$out" | grep -q 'FAIL  plugin sp@m injects a SessionStart hook' || fail "missing SessionStart finding: $out"
echo "$out" | grep -q 'WARN  tdd family has 2 skills' || fail "missing tdd family warning: $out"
echo "$out" | grep -q 'WARN  grilling family has 2 skills' || fail "missing grilling family warning: $out"
echo "$out" | grep -q 'off@m' && fail "a disabled plugin was counted as a source: $out"

# --- 2b. a SessionStart plugin with no process skill is a warning, not a failure ---
home=$(mktemp -d); proj=$(mktemp -d); mk_home "$home"; mk_project "$proj"
envp="$home/.claude/plugins/cache/m/envsetup/1.0.0"
mkdir -p "$envp/skills/node-version" "$envp/hooks" "$home/.claude/plugins"
echo "# node" > "$envp/skills/node-version/SKILL.md"
echo '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[]}]}}' > "$envp/hooks/hooks.json"
printf '{"version":2,"plugins":{"envsetup@m":[{"scope":"user","installPath":"%s"}]}}\n' "$envp" \
  > "$home/.claude/plugins/installed_plugins.json"
out=$(HOME="$home" python3 "$DOCTOR" --root "$proj" 2>&1); code=$?
[ "$code" -eq 0 ] || fail "an environment-setup SessionStart plugin should pass, got $code: $out"
echo "$out" | grep -q 'WARN  plugin envsetup@m injects a SessionStart hook' || fail "missing SessionStart warning: $out"

# --- 3. disabling the duplicates (what the field fix did) turns it green ---
echo '{"enabledPlugins":{"off@m":false,"pack@m":false,"sp@m":false}}' > "$home/.claude/settings.json"
out=$(HOME="$home" python3 "$DOCTOR" --root "$proj" 2>&1); code=$?
[ "$code" -eq 0 ] || fail "after disabling the packs it should pass, got $code: $out"
echo "$out" | grep -q 'repo-side checkpoint' || fail "inventory section missing: $out"

[ "$rc" -eq 0 ] && echo "skills-doctor: all assertions passed"
exit "$rc"
