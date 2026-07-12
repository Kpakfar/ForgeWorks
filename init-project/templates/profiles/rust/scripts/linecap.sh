#!/usr/bin/env bash
# scripts/linecap.sh -- mechanical line-cap gate (AGENTS.md <architecture-discipline>).
#
# Fails if any *.rs file in the project exceeds 200 lines. The ~100-line target
# stays a review judgment; the 200-line hard cap is enforced here so it cannot
# silently slip past review. Generated or vendored exceptions go in a committed
# `.linecap-ignore` at the project root, one path per line (exact match,
# e.g. `src/generated/schema.rs`). target/ and .claude/ are always skipped.

set -euo pipefail
cd "$(dirname "$0")/.."
CAP=200

list_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files -- '*.rs' | grep -Ev '^(target|\.claude)/' || true
  else
    find . -name '*.rs' -type f -not -path './target/*' -not -path './.claude/*' 2>/dev/null | sed 's|^\./||'
  fi
}

fail=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if [ -f .linecap-ignore ] && grep -qxF "$f" .linecap-ignore; then continue; fi
  n=$(wc -l < "$f")
  if [ "$n" -gt "$CAP" ]; then
    echo "line cap: $f has $n lines (hard cap $CAP) -- split it (one concept per file), or add it to .linecap-ignore if generated/vendored." >&2
    fail=1
  fi
done < <(list_files)
exit $fail
