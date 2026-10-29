#!/usr/bin/env bash
# A generated project must pass its OWN language-free gates on day one: every
# golden fixture is rendered, committed, and run through the same scripts its
# qa.yml and init Phase 5 run. The profile jobs own the toolchain gate; this
# owns the rest, so a fresh project's first push is green. Run from the repo root.
set -euo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
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
      python3 scripts/tamper_check.py
  ) > "$tmp/$name.log" 2>&1 || { echo "generated-gates: FAIL [$name]"; cat "$tmp/$name.log"; fail=1; continue; }
  echo "ok   [$name] features, dup, resume, prune, tamper"
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
