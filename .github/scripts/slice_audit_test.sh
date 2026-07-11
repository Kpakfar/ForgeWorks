#!/usr/bin/env bash
# Root-CI fixture test for templates/core/.claude/hooks/slice-audit.sh.
# Builds throwaway git repos and asserts every audit path, including the
# review-found edge cases: bracket tokens that are not slice headings, prefix
# ID collisions, untracked records, the full native memo->Red->Green chain,
# and the CI --range mode catching a ship move with no record at all.

set -euo pipefail
HOOK="$(cd "$(dirname "$0")/../.." && pwd)/init-project/templates/core/.claude/hooks/slice-audit.sh"
[ -f "$HOOK" ] || { echo "hook not found: $HOOK"; exit 1; }

pass=0; fail=0
expect() { # $1 want-exit  $2 label  $3 stdin-json ('' = none)  rest = hook args
  local want="$1" label="$2" json="$3"; shift 3
  local got=0
  if [ -n "$json" ]; then printf '%s' "$json" | bash "$HOOK" "$@" >/dev/null 2>&1 || got=$?
  else bash "$HOOK" "$@" >/dev/null 2>&1 || got=$?; fi
  if [ "$got" -eq "$want" ]; then echo "ok   $label"; pass=$((pass+1))
  else echo "FAIL $label (want $want, got $got)"; fail=$((fail+1)); fi
}

commit_json='{"tool_input":{"command":"git add -A && git commit -m ship"}}'
noadd_json='{"tool_input":{"command":"git commit -am ship"}}'
skip_json='{"tool_input":{"command":"SLICE_AUDIT_SKIP=1 git commit -am ship"}}'
gitc_json='{"tool_input":{"command":"git -C . commit -am ship"}}'

valid_record() { # $1 = path, $2 = slice id, $3 = origin line tail
  cat > "$1" <<EOF
# Ship record: [$2] Slice $2
- Task class: standard
- Memo: docs/designs/$2-m.md (Approved: 2026-07-11)
- Red proof: abc1234
- Green proof: def5678
- TDD audit: strong
- Evidence origin: $3
- Reviewers: code-reviewer APPROVE; security-reviewer not-triggered
- Security surface: none
- Review rounds: 1; fix rounds: 0
- Live smoke: n/a
EOF
}

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp" && git init -q -b main . && git config user.email t@t && git config user.name t
mkdir -p docs/ships docs/designs
printf '# Backlog\n## Active\n### [001] First slice\n## Shipped\n\n*(nothing yet)*\n' > docs/backlog.md
git add -A && git commit -qm init

# --- hook mode -----------------------------------------------------------
printf '# Backlog\n## Active\n## Shipped\n### [001] First slice\n' > docs/backlog.md
expect 2 "hook blocks ship without record" "$commit_json" --hook
expect 2 "hook matches 'git -C . commit' form" "$gitc_json" --hook

# Prefix collision: a valid record for 1001 must NOT satisfy slice 001.
valid_record docs/ships/1001-other.md 1001 "imported -- branch wip/1001"
git add docs/ships/1001-other.md
expect 2 "record for [1001] does not satisfy [001]" "$commit_json" --hook
rm -f docs/ships/1001-other.md; git rm -q --cached docs/ships/1001-other.md

# Valid record, but untracked + no `git add` in the command -> block.
valid_record docs/ships/001-first.md 001 "imported -- parked branch wip/001"
expect 2 "untracked record blocks 'git commit -am'" "$noadd_json" --hook
# Same command WITH git add -> pass; tracked record -> pass either way.
expect 0 "untracked record passes when command adds it" "$commit_json" --hook
git add docs/ships/001-first.md
expect 0 "tracked valid record passes" "$noadd_json" --hook

# Malformed record (field dropped) -> block; --check fails.
grep -v 'Red proof' docs/ships/001-first.md > t && mv t docs/ships/001-first.md
expect 2 "hook blocks malformed record" "$commit_json" --hook
expect 1 "--check flags malformed record" "" --check docs/ships/001-first.md
valid_record docs/ships/001-first.md 001 "imported -- parked branch wip/001"

# Bracket tokens that are NOT slice headings must not register as shipped IDs.
printf '# Backlog\n## Active\n## Shipped\n### [001] First slice\n- [x] done (see [AC1] and the [record](docs/ships/001-first.md))\n' > docs/backlog.md
expect 0 "[x]/[AC1]/link tokens are not slice IDs" "$commit_json" --hook

expect 0 "SLICE_AUDIT_SKIP bypasses" "$skip_json" --hook
expect 0 "non-git command ignored" '{"tool_input":{"command":"ls -la"}}' --hook
git checkout -q -- docs/backlog.md 2>/dev/null || true
git add -A && git commit -qm "ship 001 with record"
expect 0 "commit without ship move ignored" "$commit_json" --hook

# --- --history: full native chain memo < Red < Green <= HEAD --------------
printf 'memo\nApproved: x\n' > docs/designs/002-m.md && git add docs/designs/002-m.md && git commit -qm 'memo 002'
printf 'red' > red.txt && git add red.txt && git commit -qm 'red 002'
red=$(git rev-parse --short HEAD)
printf 'green' > green.txt && git add green.txt && git commit -qm 'green 002'
green=$(git rev-parse --short HEAD)
memo_add=$(git log --format=%h --diff-filter=A -- docs/designs/002-m.md | tail -1)
native_record() { # $1 red-hash  $2 green-hash
  cat > docs/ships/002-x.md <<EOF
# Ship record: [002] X
- Task class: standard
- Memo: docs/designs/002-m.md (Approved: x)
- Red proof: $1
- Green proof: $2
- TDD audit: strong
- Evidence origin: native
- Reviewers: code-reviewer APPROVE; security-reviewer not-triggered
- Security surface: none
- Review rounds: 1; fix rounds: 0
- Live smoke: n/a
EOF
}
native_record "$red" "$green";      expect 0 "--history accepts memo<Red<Green chain" "" --history docs/ships/002-x.md
native_record "$memo_add" "$green"; expect 1 "--history rejects memo==Red commit" "" --history docs/ships/002-x.md
native_record "$green" "$red";      expect 1 "--history rejects Green before Red" "" --history docs/ships/002-x.md
native_record "$red" "gate green (no hash)"; expect 1 "--history requires a Green commit hash" "" --history docs/ships/002-x.md
off=$(git rev-parse --short HEAD); git checkout -qb side "$memo_add" && printf 'x' > s.txt && git add s.txt && git commit -qm side
side=$(git rev-parse --short HEAD); git checkout -q main
native_record "$side" "$green";     expect 1 "--history rejects Red from another branch" "" --history docs/ships/002-x.md
rm -f docs/ships/002-x.md

# --- --range: CI catches a ship move with NO record change ----------------
base=$(git rev-parse HEAD)
printf '# Backlog\n## Active\n## Shipped\n### [001] First slice\n### [003] Sneaky slice\n' > docs/backlog.md
git add docs/backlog.md && git commit -qm "ship 003 without a record"
expect 1 "--range flags shipped slice with no record" "" --range "$base" HEAD
valid_record docs/ships/003-s.md 003 "imported -- prior session, PR #7"
git add docs/ships/003-s.md && git commit -qm "add 003 record"
expect 0 "--range passes once record is committed" "" --range "$base" HEAD

# --- --range sweep 2: tampering with an ALREADY-shipped slice's record -----
base=$(git rev-parse HEAD)   # 003 is shipped WITH its record at base
grep -v 'Red proof' docs/ships/003-s.md > t && mv t docs/ships/003-s.md
git add docs/ships/003-s.md && git commit -qm "corrupt 003 record, no backlog change"
expect 1 "--range flags corrupted record of already-shipped slice" "" --range "$base" HEAD
git revert --no-edit HEAD >/dev/null 2>&1
git rm -q docs/ships/003-s.md && git commit -qm "delete 003 record, no backlog change"
expect 1 "--range flags deleted record of still-shipped slice" "" --range "$base" HEAD
git revert --no-edit HEAD >/dev/null 2>&1
expect 0 "--range passes after tampering reverted" "" --range "$base" HEAD

echo "----"; echo "slice-audit fixtures: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
