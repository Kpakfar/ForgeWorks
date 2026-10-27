#!/usr/bin/env bash
# The loop's state scripts (feature.py, resume.py, prune.py, features_check.py)
# on a rendered fixture: a feature walks GRILL -> done and every pointer agrees
# at each step. Run from the repo root.
set -euo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
python3 init-project/render.py --answers .github/fixtures/golden/python-ai-full.json \
  --core init-project/templates/core --profile init-project/templates/profiles/python \
  --out "$tmp/proj" >/dev/null
# A roster with codex links .agents/skills; a real directory there is the owner's and stays.
test -L "$tmp/proj/.agents/skills" || { echo "loop-scripts: FAIL -- no .agents/skills link"; exit 1; }
mkdir -p "$tmp/own/.agents/skills/mine"
python3 init-project/render.py --answers .github/fixtures/golden/python-ai-full.json \
  --core init-project/templates/core --profile init-project/templates/profiles/python \
  --out "$tmp/own" >/dev/null
test -d "$tmp/own/.agents/skills/mine" || { echo "loop-scripts: FAIL -- render replaced a real .agents/skills"; exit 1; }
# Init-time dependency edges point backwards only.
python3 - "$tmp" <<'PY2'
import json, subprocess, sys
ans = json.load(open(".github/fixtures/golden/python-ai-full.json"))
ans["features"][0]["depends_on"] = [ans["features"][1]["id"]]
json.dump(ans, open(sys.argv[1] + "/bad.json", "w"))
r = subprocess.run([sys.executable, "init-project/render.py", "--answers", sys.argv[1] + "/bad.json",
                    "--core", "init-project/templates/core", "--profile", "init-project/templates/profiles/python",
                    "--out", sys.argv[1] + "/bad"], capture_output=True, text=True)
sys.exit(0 if r.returncode != 0 and "depends_on" in (r.stdout + r.stderr) else "loop-scripts: FAIL -- forward depends_on rendered")
PY2
cd "$tmp/proj" && git init -q && git -c user.name=ci -c user.email=ci@example.com commit -q --allow-empty -m init && git add -A && git -c user.name=ci -c user.email=ci@example.com commit -qm scaffold
ok() { out=$("$@" 2>&1) || { echo "loop-scripts: FAIL -- $*"; echo "$out"; exit 1; }; }
fails() { if out=$("$@" 2>&1); then echo "loop-scripts: FAIL -- expected failure: $*"; echo "$out"; exit 1; fi; }
ok python3 scripts/features_check.py
python3 scripts/resume.py | grep -q "Nothing in progress" || { echo "FAIL idle brief"; exit 1; }
ok python3 scripts/feature.py F001 status=in-progress phase=grill next="draft plan"
ok python3 scripts/resume.py --check                      # grill without a plan resumes
printf '# F001\n\n## Decisions\n- x\n' > docs/plans/F001.md
printf '<html></html>\n' > docs/design/mockups/F001-list.html
ok python3 scripts/feature.py F001 mockup=docs/design/mockups/F001-list.html
git checkout -qb feat/F001-x
ok python3 scripts/feature.py F001 phase=red tests+=tests/test_example.py::test_greet
python3 scripts/resume.py | grep -q "RED -> next GREEN" || { echo "FAIL brief phase"; exit 1; }
fails python3 scripts/feature.py F001 phase=bogus
python3 scripts/feature.py F001 | grep -q '"phase": "red"' || { echo "FAIL invalid update landed"; exit 1; }
ok python3 scripts/feature.py F001 notes+="deviation: kept sync I/O"
# feature.py owns the edges: no skipped phase, no close before REVIEW, a counted review cap.
fails python3 scripts/feature.py F001 phase=review                                     # skips GREEN
fails python3 scripts/feature.py F001 status=done                                      # closes from REVIEW only
python3 scripts/feature.py F001 | grep -q '"phase": "red"' || { echo "FAIL refused edge landed"; exit 1; }
ok python3 scripts/feature.py F001 phase=green
ok python3 scripts/feature.py F001 phase=review
ok python3 scripts/feature.py F001 phase=green                                         # a fix pass goes back
ok python3 scripts/feature.py F001 phase=review                                        # the one re-review
ok python3 scripts/feature.py F001 phase=green
fails python3 scripts/feature.py F001 phase=review                                     # cap hit
fails python3 scripts/feature.py F001 phase=review override=                           # the owner's reason is owed
ok python3 scripts/feature.py F001 phase=review override="owner: auth changed, one more pass"
python3 scripts/feature.py F001 | grep -q 'override: owner: auth changed' || { echo "FAIL override not on the record"; exit 1; }
python3 scripts/feature.py F001 | grep -q '"reviews": 3' || { echo "FAIL reviews not counted"; exit 1; }
ok python3 scripts/feature.py F001 status=done
python3 scripts/resume.py | grep -q "F001 is closed on branch feat/F001-x but not merged" || { echo "FAIL closed-unmerged brief"; exit 1; }
python3 scripts/feature.py F001 | grep -q '"phase"' && { echo "FAIL phase must drop on done"; exit 1; }
fails python3 scripts/features_check.py                  # leftover plan
python3 scripts/prune.py | grep -q "deleted docs/plans/F001.md" || { echo "FAIL prune"; exit 1; }
grep -q '\[x\] \*\*F001\*\*' docs/BACKLOG.md || { echo "FAIL backlog regen"; exit 1; }
ok python3 scripts/prune.py --check
ok python3 scripts/features_check.py
ok python3 scripts/resume.py --check
# A visual feature builds its mockup during GRILL, so the mockup is owed from RED on.
ok python3 scripts/feature.py F002 surface=dashboard status=in-progress phase=grill next="build mockups"
fails python3 scripts/feature.py F002 phase=red
python3 scripts/feature.py F002 | grep -q '"phase": "grill"' || { echo "FAIL rejected update landed"; exit 1; }
ok python3 scripts/feature.py F002 surface=none status=todo
# Decisions outlive the plan; dependencies decide what `go` offers next.
ok python3 scripts/feature.py F001 decisions+="owner said no to offline mode"
fails python3 scripts/feature.py F002 depends_on+=F999         # unknown id
fails python3 scripts/feature.py F001 depends_on+=F001         # own id
ok python3 scripts/feature.py F002 depends_on+=F003
fails python3 scripts/feature.py F003 depends_on+=F002         # cycle
python3 scripts/resume.py | grep -q "F003" || { echo "FAIL go must skip the blocked F002"; exit 1; }
ok python3 scripts/backlog.py
grep -q 'F002.*waits for F003' docs/BACKLOG.md || { echo "FAIL backlog must show the wait"; exit 1; }
fails python3 scripts/feature.py F003 status=in-progress phase=grill   # no `next`
fails python3 scripts/feature.py F003 status=in-progress phase=red next="write tests"   # starts at GRILL
ok python3 scripts/feature.py F003 status=in-progress phase=grill next="draft plan"
ok python3 scripts/feature.py F003 phase=red
fails python3 scripts/feature.py F003 phase=green              # no cited test
fails python3 scripts/feature.py F003 tier=chore status=done tests+=tests/test_example.py::test_greet   # no tier flip to skip REVIEW
fails python3 scripts/feature.py F003 tier=chore
ok python3 scripts/feature.py F003 status=todo
fails python3 scripts/feature.py F002 status=in-progress phase=grill next="draft plan"   # waits for F003
ok python3 scripts/feature.py F003 tier=chore
ok python3 scripts/feature.py F003 status=done tests+=tests/test_example.py::test_greet   # a chore closes without the loop
ok python3 scripts/feature.py F002 status=in-progress phase=grill next="draft plan"
echo "loop-scripts: OK"
