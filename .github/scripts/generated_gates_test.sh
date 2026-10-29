#!/usr/bin/env bash
# A generated project must pass its OWN language-free gates on day one: every
# golden fixture is rendered, committed, and run through the same scripts its
# qa.yml and init Phase 5 run. The profile jobs own the toolchain gate; this
# owns the rest, so a fresh project's first push is green. Run from the repo root.
set -euo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
# Run one budget job's `run: |` script exactly as the rendered qa.yml has it.
budget_job() {
  awk -v job="  $1:" '
    $0 == job { injob = 1; next }
    injob && /^  [a-z-]+:$/ { exit }
    injob && /^        run: [|]$/ { inrun = 1; next }
    inrun && /^          / { print substr($0, 11); next }
    inrun && /^$/ { print; next }
    inrun { exit }' .github/workflows/qa.yml > "$tmp/job.sh"
  [ -s "$tmp/job.sh" ] || { echo "no $1 job in qa.yml"; return 1; }
  bash "$tmp/job.sh"
}
for answers in .github/fixtures/golden/*.json; do
  name=$(basename "$answers" .json)
  lang=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["stack"]["language"])' "$answers")
  out="$tmp/$name"
  python3 init-project/render.py --answers "$answers" --core init-project/templates/core \
    --profile "init-project/templates/profiles/$lang" --out "$out" >/dev/null
  (
    # && chains on purpose: set -e is off inside a subshell that `||` follows.
    cd "$out" && git init -q -b main && git add -A &&
      git -c user.name=ci -c user.email=ci@example.com commit -qm "chore: bootstrap project" &&
      python3 scripts/features_check.py && python3 scripts/dup_check.py &&
      python3 scripts/resume.py --check && python3 scripts/prune.py --check &&
      python3 scripts/tamper_check.py && budget_job docs-budget && budget_job checkpoint-budget
  ) > "$tmp/$name.log" 2>&1 || { echo "generated-gates: FAIL [$name]"; cat "$tmp/$name.log"; fail=1; continue; }
  # Stack-free: only a TypeScript project may need Node. deps-guard names npm
  # because it blocks installs for every package manager, so it is exempt.
  if [ "$lang" != typescript ]; then
    leak=$(grep -rnE '\bnpx\b|\bnpm\b|node:|Node\.js' "$out" --exclude=deps-guard.sh --exclude-dir=.git || true)
    [ -z "$leak" ] || { echo "generated-gates: FAIL [$name] a $lang project depends on Node:"; echo "$leak"; fail=1; continue; }
  fi
  echo "ok   [$name] features, dup, resume, prune, tamper, docs-budget, checkpoint-budget, no Node"
done
# The import-line skip must not blind the gate: a copied function body still fails.
probe="$tmp/python-ai-full"
if [ -d "$probe" ]; then
  body=$'def tally(rows):\n    total = 0\n    for row in rows:\n        total += row.amount * row.count\n        if total > row.limit:\n            raise ValueError(row.name)\n    return total\n'
  printf 'import os\n\n%s' "$body" > "$probe/src/copy_a.py"
  printf 'import sys\n\n%s' "$body" > "$probe/src/copy_b.py"
  if (cd "$probe" && python3 scripts/dup_check.py >/dev/null); then
    echo "generated-gates: FAIL -- dup_check missed a copied function"; fail=1
  else
    echo "ok   dup_check still fails a copied function body"
  fi
fi
exit $fail
