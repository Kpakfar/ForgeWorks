#!/usr/bin/env bash
# .claude/hooks/slice-audit.sh
#
# Agent-neutral ship audit (see AGENTS.md <delivery-evidence>). Two callers:
#   --hook          PreToolUse hook on Bash (stdin JSON). Acts only on `git commit`
#                   commands. If the uncommitted backlog change moves a slice to
#                   Shipped, requires a valid docs/ships/ record. Exit 2 blocks.
#   --check FILE..  Validate ship-record files (fields present). Used by CI and
#                   humans. Exit 1 on failure.
#   --history FILE  Order check for `Evidence origin: native`: memo-add commit
#                   strictly precedes Red, Red strictly precedes Green, both are
#                   ancestors of HEAD. Needs a full clone. Exit 1 on failure.
#   --range BASE [HEAD]  CI mode: every slice newly Shipped in the backlog
#                   between the two revs must have a committed, valid record at
#                   HEAD (catches no-record ship moves and record deletions).
#                   Also emits a NON-FAILING tech-debt cadence warning: if 3+
#                   slices are Shipped at HEAD and docs/proposals-ideas.md has
#                   no dated heading mentioning tech-debt, it prints
#                   'WARN tech-debt sweep overdue' to stderr. The warning never
#                   changes the exit code (cadence is reviewer-owned, the audit
#                   only surfaces it).
#
# Deterministic and grep-based on purpose: it proves presence and order, not
# truthfulness -- reviewers judge content. False positive on a legitimate commit?
# Prefix the segment with SLICE_AUDIT_SKIP=1 (with the user's OK) to pass.

set -euo pipefail
BACKLOG="docs/backlog.md"
SHIPS_DIR="docs/ships"
FIELDS='Task class|Memo|Red proof|Green proof|TDD audit|Evidence origin|Reviewers|Security surface|Review rounds|Live smoke'

check_record() { # $1 = record file; prints missing fields, returns 1 if invalid
  local f="$1" miss=0 key
  [ -f "$f" ] || { echo "slice-audit: missing record file: $f" >&2; return 1; }
  set -f; IFS='|'
  for key in $FIELDS; do
    grep -Eq "^- ${key}:" "$f" || { echo "slice-audit: $f lacks field '- ${key}:'" >&2; miss=1; }
  done
  unset IFS; set +f
  grep -Eq '^- TDD audit: (strong|weak)' "$f" || { echo "slice-audit: $f TDD audit must be strong|weak" >&2; miss=1; }
  grep -Eq '^- Evidence origin: (native|imported)' "$f" || { echo "slice-audit: $f Evidence origin must be native|imported" >&2; miss=1; }
  return $miss
}

shipped_ids() { # $1 = a backlog file; prints slice IDs from HEADING lines in ## Shipped
  # Only `### [ID] ...` headings count -- checkboxes ([x]), link text, and [AC1]
  # references inside a row must not register as slices.
  awk '/^## Shipped/{s=1;next} /^## /{s=0} s && /^#{3,4} \[/' "$1" \
    | sed -E 's/^#{3,4} \[([^]]+)\].*/\1/' | sort -u || true
}

record_for_id() { # $1 = id without brackets; echoes matching record path or nothing
  # Exact-token match only: filename `<id>.md` / `<id>-*.md`, or a first line
  # containing the literal `[<id>]` -- so slice 001 never accepts 1001-other.md
  # and regex metacharacters in IDs stay inert (grep -F).
  local id="$1" f base
  for f in "$SHIPS_DIR"/*.md; do
    [ -e "$f" ] || return 0
    base=$(basename "$f")
    case "$base" in README.md) continue;; "$id.md"|"$id-"*) echo "$f"; return 0;; esac
    if head -1 "$f" | grep -qF "[$id]"; then echo "$f"; return 0; fi
  done
}

case "${1:---hook}" in
--check)
  shift; rc=0
  [ $# -gt 0 ] || { echo "slice-audit: --check needs at least one file" >&2; exit 1; }
  for f in "$@"; do check_record "$f" || rc=1; done
  exit $rc
  ;;
--history)
  # Native evidence must prove the whole chain IN THIS BRANCH:
  # memo-add commit ≺ Red commit ≺ Green commit ≼ HEAD.
  shift; f="${1:?record file required}"
  grep -Eq '^- Evidence origin: native' "$f" || exit 0   # imported: reviewer judges provenance
  memo=$(grep -E '^- Memo:' "$f" | grep -oE 'docs/designs/[^ )]+' | head -1 || true)
  red=$(grep -E '^- Red proof:' "$f" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1 || true)
  green=$(grep -E '^- Green proof:' "$f" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1 || true)
  [ -n "$memo" ]  || { echo "slice-audit: $f (native) Memo field names no docs/designs/ path" >&2; exit 1; }
  [ -n "$red" ]   || { echo "slice-audit: $f (native) Red proof has no commit hash" >&2; exit 1; }
  [ -n "$green" ] || { echo "slice-audit: $f (native) Green proof has no commit hash (native = separate memo/Red/Green commits)" >&2; exit 1; }
  memo_c=$(git log --diff-filter=A --format=%H --follow -- "$memo" | tail -1 || true)
  [ -n "$memo_c" ] || { echo "slice-audit: $f memo $memo has no add-commit in history" >&2; exit 1; }
  for c in "$red" "$green"; do
    git cat-file -e "$c^{commit}" 2>/dev/null || { echo "slice-audit: $f commit $c not found" >&2; exit 1; }
    git merge-base --is-ancestor "$c" HEAD || { echo "slice-audit: $f commit $c is not an ancestor of HEAD (evidence from another branch?)" >&2; exit 1; }
  done
  [ "$memo_c" != "$(git rev-parse "$red")" ] && git merge-base --is-ancestor "$memo_c" "$red" \
    || { echo "slice-audit: $f memo commit is not a strict ancestor of Red commit $red" >&2; exit 1; }
  [ "$(git rev-parse "$red")" != "$(git rev-parse "$green")" ] && git merge-base --is-ancestor "$red" "$green" \
    || { echo "slice-audit: $f Red commit $red is not a strict ancestor of Green commit $green" >&2; exit 1; }
  exit 0
  ;;
--range)
  # CI mode, two sweeps over $2..$3 (default HEAD):
  #  (1) every slice NEWLY Shipped in the backlog must have a committed, valid
  #      record at HEAD (catches ship moves with no record change);
  #  (2) every ship record MODIFIED or DELETED in the range is re-audited
  #      (catches tampering with / removal of an already-shipped slice's record).
  shift; base="${1:?base rev required}"; head_rev="${2:-HEAD}"; rc=0
  oldb=$(mktemp); newb=$(mktemp); trap 'rm -f "$oldb" "$newb"' EXIT
  git show "$base:$BACKLOG"     > "$oldb" 2>/dev/null || : > "$oldb"
  git show "$head_rev:$BACKLOG" > "$newb" 2>/dev/null || : > "$newb"
  new_ids=$(comm -13 <(shipped_ids "$oldb") <(shipped_ids "$newb"))
  for id in $new_ids; do
    rec=$(record_for_id "$id")
    if [ -z "$rec" ] || ! git cat-file -e "$head_rev:$rec" 2>/dev/null; then
      echo "slice-audit: [$id] shipped in $base..$head_rev but no committed docs/ships/ record names it." >&2; rc=1; continue
    fi
    check_record "$rec" || rc=1
    "$0" --history "$rec" || rc=1
  done
  # Sweep 2: records touched in the range. --no-renames so a `git mv` decomposes
  # into D+A and cannot smuggle a tampered record past a rename status (Rxxx).
  while IFS=$'\t' read -r status f; do
    [ -n "$f" ] || continue
    case "$(basename "$f")" in README.md) continue;; esac
    if [ "$status" = "D" ]; then
      # Deleted record: if its slice is still Shipped at HEAD, a replacement
      # record must exist and validate -- otherwise it is evidence removal.
      del_id=$(git show "$base:$f" 2>/dev/null | head -1 | grep -oE '\[[^]]+\]' | head -1 | tr -d '[]' || true)
      if [ -n "$del_id" ] && shipped_ids "$newb" | grep -qxF "$del_id"; then
        repl=$(record_for_id "$del_id")
        if [ -z "$repl" ]; then
          echo "slice-audit: $f deleted in $base..$head_rev but [$del_id] is still Shipped -- ship records are permanent evidence." >&2; rc=1
        else
          check_record "$repl" || rc=1
          "$0" --history "$repl" || rc=1
        fi
      fi
    else
      # Added or modified record: re-validate (re-auditing a sweep-1 record is harmless).
      check_record "$f" || rc=1
      "$0" --history "$f" || rc=1
    fi
  done < <(git diff --name-status --no-renames --diff-filter=AMD "$base" "$head_rev" -- "$SHIPS_DIR" | grep -E '\.md$' || true)
  # Tech-debt cadence check -- WARNING ONLY, deliberately never touches $rc.
  # <recurring-reviews> asks for a @tech-debt sweep every 3rd shipped slice,
  # evidenced by a dated heading in docs/proposals-ideas.md. Deterministic
  # floor: 3+ Shipped slices at HEAD and NO heading line that carries both a
  # YYYY-MM-DD date and the word tech-debt (case-insensitive) -> warn.
  shipped_total=$(shipped_ids "$newb" | grep -c . || true)
  if [ "$shipped_total" -ge 3 ]; then
    if ! git show "$head_rev:docs/proposals-ideas.md" 2>/dev/null \
        | grep -Ei '^#{2,} ' | grep -Ei 'tech-?debt' | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
      echo "slice-audit: WARN tech-debt sweep overdue ($shipped_total slices Shipped, no dated tech-debt heading in docs/proposals-ideas.md -- run @tech-debt, see AGENTS.md <recurring-reviews>). Not blocking." >&2
    fi
  fi
  exit $rc
  ;;
--hook)
  input=$(cat)
  if command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  elif command -v python3 >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)
  else
    echo "slice-audit: neither jq nor python3 found -- ship audit is NOT inspecting commits." >&2; exit 0
  fi
  [ -z "$cmd" ] && exit 0
  # Match `git commit` including global-flag forms (`git -C . commit`, `git -c k=v commit`).
  printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0
  printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])SLICE_AUDIT_SKIP=1[[:space:]]' && exit 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  [ -f "$BACKLOG" ] || exit 0
  # Uncommitted (staged or not -- the hook fires before `git add` in a compound
  # command runs) backlog delta vs HEAD: which IDs are newly in ## Shipped?
  old=$(mktemp); git show "HEAD:$BACKLOG" > "$old" 2>/dev/null || : > "$old"
  new_ids=$(comm -13 <(shipped_ids "$old") <(shipped_ids "$BACKLOG") | tr -d '[]')
  rm -f "$old"
  [ -z "$new_ids" ] && exit 0
  fail=0
  for id in $new_ids; do
    rec=$(record_for_id "$id")
    if [ -z "$rec" ]; then
      echo "slice-audit: backlog moves [$id] to Shipped but no docs/ships/ record names it." >&2; fail=1
    elif ! git ls-files --error-unmatch "$rec" >/dev/null 2>&1 && \
         ! printf '%s' "$cmd" | grep -qF "git add"; then
      # Untracked record: `git commit -am` would NOT include it -- the record must
      # land in the same commit as the backlog move.
      echo "slice-audit: $rec exists but is untracked -- 'git add' it so it ships in this commit." >&2; fail=1
    else
      check_record "$rec" || fail=1
    fi
  done
  if [ "$fail" -eq 1 ]; then
    {
      echo "Ship audit (see AGENTS.md <delivery-evidence>): a slice cannot move to Shipped without a valid ship record."
      echo "Write docs/ships/<slice>.md per docs/ships/README.md (all '- Field:' lines present), include it in this commit, and retry."
      echo "This local check reads the working tree (a speed bump, not a boundary -- it may also fire if an unrelated"
      echo "commit leaves a pending backlog move uncommitted); the CI ship-audit job on the pushed range is the authority."
      echo "False positive? Re-run with SLICE_AUDIT_SKIP=1 at the start of the command -- with the user's OK."
    } >&2
    exit 2
  fi
  exit 0
  ;;
*)
  echo "usage: slice-audit.sh [--hook | --check FILE.. | --history FILE | --range BASE [HEAD]]" >&2; exit 1
  ;;
esac
