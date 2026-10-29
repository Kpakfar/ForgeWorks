#!/usr/bin/env bash
# render.py writes a tree only when every check passed, and never overwrites a
# file it did not put there without --allow-overwrite. Run from the repo root.
set -euo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
render() { # render <out> [flags] -> the renderer's output; never fails
  python3 init-project/render.py --answers "$tmp/answers.json" \
    --core init-project/templates/core --profile init-project/templates/profiles/python \
    --out "$@" 2>&1 || true
}
fail() { echo "render-guard: FAIL -- $1"; exit 1; }
cp .github/fixtures/golden/python-ai-full.json "$tmp/answers.json"

# A bootstrap kit's files are expected; the stamp it wrote is kept.
d="$tmp/kit"; mkdir -p "$d/.claude"
printf '# AGENTS.md (Bootstrap Mode)\n' > "$d/AGENTS.md"; echo main > "$d/.claude/.template-version"
render "$d" | grep -q "^rendered" || fail "a bootstrap kit folder did not render"
[ "$(cat "$d/.claude/.template-version")" = main ] || fail "the bootstrap stamp was replaced"
render "$d" | grep -q "^rendered" || fail "an identical re-render collided"

# An owner's file stops the render, and nothing at all is written.
d="$tmp/owner"; mkdir "$d"; echo "keep me" > "$d/README.md"; echo "secret.txt" > "$d/.gitignore"
out=$(render "$d")
echo "$out" | grep -q "would be overwritten" || fail "an owner's README did not stop the render: $out"
[ "$(ls -A "$d" | wc -l | tr -d ' ')" = 2 ] || fail "a stopped render wrote files"
grep -q secret.txt "$d/.gitignore" || fail "a stopped render changed .gitignore"
render "$d" --allow-overwrite | grep -q "^rendered" || fail "--allow-overwrite did not render"

# An owner's CLAUDE.md is a collision, not a file to delete.
d="$tmp/claude"; mkdir "$d"; echo "my rules" > "$d/CLAUDE.md"
render "$d" | grep -q "CLAUDE.md" || fail "an owner's CLAUDE.md was not reported"
grep -q "my rules" "$d/CLAUDE.md" || fail "an owner's CLAUDE.md was replaced"

# A folder that is a symlink out of --out is never followed.
d="$tmp/escape"; mkdir "$d" "$tmp/elsewhere"; ln -s "$tmp/elsewhere" "$d/docs"
render "$d" | grep -q "outside --out" || fail "a symlinked folder out of --out was followed"
[ -z "$(ls -A "$tmp/elsewhere")" ] || fail "the render wrote through a symlink"

# The AGENTS.md cap counts bytes, as the docs-budget job's `wc -c` does: an
# answer that fits in characters but not in bytes must fail here, not in CI.
d="$tmp/bytes"; mkdir "$d"
python3 - "$tmp/answers.json" "$tmp/wide.json" <<'PY'
import json, sys
a = json.load(open(sys.argv[1])); a["project"]["goal"] += " " + "é" * 70
json.dump(a, open(sys.argv[2], "w"), ensure_ascii=False)
PY
out=$(python3 init-project/render.py --answers "$tmp/wide.json" --core init-project/templates/core \
  --profile init-project/templates/profiles/python --out "$d" 2>&1 || true)
echo "$out" | grep -q "bytes; hard cap" || fail "a multi-byte AGENTS.md over the byte cap rendered: $out"

# A failed render (bad answers) writes nothing.
d="$tmp/bad"; mkdir "$d"
python3 - "$tmp/answers.json" <<'PY'
import json, sys
p = sys.argv[1]
a = json.load(open(p)); a["project"]["slug"] = "Not A Slug"; json.dump(a, open(p, "w"))
PY
render "$d" >/dev/null
[ -z "$(ls -A "$d")" ] || fail "a failed render left files behind"
echo "render-guard: OK"
