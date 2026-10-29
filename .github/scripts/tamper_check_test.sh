#!/usr/bin/env bash
# The tamper guard on a rendered Rust project: a direct push to main, an inline
# Rust test, and a gate file each need a `test-change:` reason; an added test,
# a plain source edit, and a branch's first push do not. Run from the repo root.
set -euo pipefail
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
python3 init-project/render.py --answers .github/fixtures/golden/rust-minimal.json \
  --core init-project/templates/core --profile init-project/templates/profiles/rust \
  --out "$tmp/p" >/dev/null
cd "$tmp/p"
g() { git -c user.name=ci -c user.email=ci@example.com "$@"; }
g init -q -b main && git add -A && g commit -qm "chore: bootstrap project"
start=$(git rev-parse HEAD)

check() { # check <label> <expect: OK|FAIL|SKIP> <commit message> [base]
  local label="$1" want="$2" msg="$3" base="${4:-$start}"
  git add -A && g commit -qm "$msg"
  out=$(TAMPER_BASE="$base" python3 scripts/tamper_check.py 2>&1 || true)
  echo "$out" | grep -q "tamper-check: $want" || { echo "tamper-check-test: FAIL -- $label"; echo "$out"; exit 1; }
  git reset -q --hard "$start"
}

sed -i.bak 's/        assert_eq!(greet("world"), "Hello, world!");//' src/lib.rs && rm src/lib.rs.bak
check "an inline Rust assertion removed on a direct push" FAIL "refactor: tidy"
sed -i.bak 's/        assert_eq!(greet("world"), "Hello, world!");//' src/lib.rs && rm src/lib.rs.bak
check "an inline Rust assertion removed with a reason" OK $'refactor: tidy\n\ntest-change: greet is gone'
printf '\n// edited\n' >> tests/e2e.rs
check "a test file edited on a direct push" FAIL "fix: e2e"
printf '\n# edited\n' >> .github/workflows/qa.yml
check "a workflow edited" FAIL "ci: tweak"
printf '\n# edited\n' >> .github/workflows/qa.yml
check "a workflow edited with a reason" OK $'ci: tweak\n\ntest-change: faster runner'
sed -i.bak -E 's/(uses: actions\/checkout@)[0-9a-f]{40} # v4/\13d3c42e5aac5ba805825da76410c181273ba90b1 # v6/' .github/workflows/qa.yml && rm .github/workflows/qa.yml.bak
check "a Dependabot pin bump in a workflow" OK "chore(deps): bump actions/checkout"
sed -i.bak -E 's/(uses: actions\/checkout@)[0-9a-f]{40} # v4/\13d3c42e5aac5ba805825da76410c181273ba90b1 # v6/' .github/workflows/qa.yml && rm .github/workflows/qa.yml.bak
printf '\n# edited\n' >> .github/workflows/qa.yml
check "a pin bump plus another workflow edit" FAIL "chore(deps): bump actions/checkout"
printf 'echo hi\n' >> scripts/qa.sh
check "a QA runner edited" FAIL "chore: qa"
printf '#[test]\nfn extra() {}\n' > tests/extra.rs
check "an added test" OK "test: extra"
sed -i.bak 's/Hello, {name}!/Hi, {name}!/' src/lib.rs && rm src/lib.rs.bak
check "a plain source edit" OK "feat: shorter greeting"
printf '\n// edited\n' >> tests/e2e.rs
check "a branch's first push (all-zero base)" SKIP "fix: e2e" 0000000000000000000000000000000000000000
echo "tamper-check-test: OK"
