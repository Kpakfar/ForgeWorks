#!/usr/bin/env bash
# Regression test for the deps-guard hook: assert it BLOCKS (exit 2) the
# install / remote-execute commands and ALLOWS (exit 0) lockfile / vetted /
# unrelated ones. Run from the repo root.
set -uo pipefail

H="init-project/templates/core/.claude/hooks/deps-guard.sh"
rc=0

run() { # command -> exit code
  printf '%s' "{\"tool_input\":{\"command\":$(printf '%s' "$1" | jq -R .)}}" | bash "$H" >/dev/null 2>&1
  echo $?
}
expect() { # want command
  local want="$1" cmd="$2" got
  got=$(run "$cmd")
  if [ "$got" != "$want" ]; then
    echo "FAIL want=$want got=$got : $cmd"; rc=1
  else
    echo "ok   ($got) : $cmd"
  fi
}

# MUST BLOCK (2)
for c in \
  'npm install lodash' 'npm install --save lodash' 'npm --prefix . install evil' \
  'pnpm add -D vitest' 'yarn add x' 'uv add httpx' 'uv pip install x' \
  'pip install -U requests' 'pipx install x' 'poetry add flask' \
  'cargo add serde' 'cargo install ripgrep' 'cargo update' \
  'go get example.com/x' 'go install example.com/x@latest' 'gem install x' \
  'npx cowsay' 'npx -y cowsay' 'npx --yes cowsay' 'bunx evil' 'uvx evil' \
  'uvx --from pkg cmd' 'pnpm dlx evil' 'yarn dlx evil' 'npm exec evil' \
  'npm --prefix . install evil' \
  'echo DEPS_VETTED && npm install evil' 'DEPS_VETTED=0 npm install evil'; do
  expect 2 "$c"
done

# MUST ALLOW (0)
for c in \
  'DEPS_VETTED=1 uv add httpx' 'DEPS_VETTED=1 npx playwright install' \
  'uv sync' 'npm ci' 'pnpm install' 'pip install -r requirements.txt' \
  'pip install -e .' 'poetry install' 'go build ./...' 'go mod download' \
  'cargo build' 'npm --prefix . test' 'ls -la && echo hi' 'git status'; do
  expect 0 "$c"
done

[ "$rc" = 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT"
exit $rc
