#!/usr/bin/env bash
# line_cap_test.sh -- proves the per-profile line-cap gate (hard cap 200 lines,
# AGENTS.md <architecture-discipline>) without needing full toolchains:
#   - Python + Go + Rust `scripts/linecap.sh`: green on the shipped scaffold, red
#     on a synthetic 201-line file, green at exactly 200 lines, green again when
#     the offender is allowlisted in .linecap-ignore.
#   - Exercises BOTH file-listing paths: git ls-files (Go fixture is a git repo)
#     and the find fallback (Python and Rust fixtures are bare directories).
# TypeScript's cap is eslint's max-lines rule; the typescript-profile CI job
# proves it fires on a synthetic 201-line file after npm install.

set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail=0

expect() { # $1=0|1 expected exit, $2=label, rest=command
  local want="$1" label="$2"; shift 2
  if "$@" >/dev/null 2>&1; then got=0; else got=1; fi
  if [ "$got" = "$want" ]; then echo "PASS: $label"
  else echo "FAIL: $label (expected exit $want, got $got)" >&2; fail=1; fi
}

gen_lines() { # $1=file $2=count $3=line-prefix
  python3 -c "open('$1','w').write(''.join(f'$3{i}\n' for i in range($2)))"
}

# ---- Python fixture (no git repo -> find fallback) ----
PY="$TMP/py"
cp -R "$ROOT/init-project/templates/profiles/python" "$PY"
expect 0 "python: scaffold is green" bash "$PY/scripts/linecap.sh"
gen_lines "$PY/src/exactly200.py" 200 "x200_ = "
expect 0 "python: 200-line file passes" bash "$PY/scripts/linecap.sh"
gen_lines "$PY/src/toolong.py" 201 "x_ = "
expect 1 "python: 201-line file fails" bash "$PY/scripts/linecap.sh"
echo "src/toolong.py" > "$PY/.linecap-ignore"
expect 0 "python: .linecap-ignore allowlists it" bash "$PY/scripts/linecap.sh"

# ---- Go fixture (git repo -> git ls-files path) ----
GO="$TMP/go"
cp -R "$ROOT/init-project/templates/profiles/go" "$GO"
git -C "$GO" init -q && git -C "$GO" add -A
expect 0 "go: scaffold is green" bash "$GO/scripts/linecap.sh"
gen_lines "$GO/toolong.go" 201 "// filler "
git -C "$GO" add -A
expect 1 "go: 201-line file fails" bash "$GO/scripts/linecap.sh"
echo "toolong.go" > "$GO/.linecap-ignore"
expect 0 "go: .linecap-ignore allowlists it" bash "$GO/scripts/linecap.sh"
mkdir -p "$GO/vendor" && gen_lines "$GO/vendor/big.go" 300 "// v "
git -C "$GO" add -A
expect 0 "go: vendor/ is always skipped" bash "$GO/scripts/linecap.sh"

# ---- Rust fixture (no git repo -> find fallback; target/ always skipped) ----
RS="$TMP/rust"
cp -R "$ROOT/init-project/templates/profiles/rust" "$RS"
expect 0 "rust: scaffold is green" bash "$RS/scripts/linecap.sh"
gen_lines "$RS/src/toolong.rs" 201 "// filler "
expect 1 "rust: 201-line file fails" bash "$RS/scripts/linecap.sh"
echo "src/toolong.rs" > "$RS/.linecap-ignore"
expect 0 "rust: .linecap-ignore allowlists it" bash "$RS/scripts/linecap.sh"
mkdir -p "$RS/target/debug" && gen_lines "$RS/target/debug/gen.rs" 300 "// t "
expect 0 "rust: target/ is always skipped" bash "$RS/scripts/linecap.sh"

[ "$fail" -eq 0 ] && echo "==> line-cap tests passed."
exit $fail
