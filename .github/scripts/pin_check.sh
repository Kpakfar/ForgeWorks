#!/usr/bin/env bash
# pin_check.sh -- supply-chain pin check for the template's CI surfaces.
#
# Fails if:
#   1. any workflow-shaped source (root workflows, the template's qa.yml, the
#      ci_setup_steps YAML inside init-project/SKILL.md, or the ci_setup_steps
#      lines in each profile's profile.json) has a `uses:` that is not pinned
#      to a full 40-hex commit SHA (tag-only pins are mutable), or
#   2. any of those sources -- plus the profile Dockerfiles -- pipes a download
#      straight into a shell (`curl ... | sh` and friends). Downloads must land
#      in a file and be checksum-verified before execution, or
#   3. a doc, skill, or template runs `npx`/`uvx` on a package without an exact
#      version (the project's own devDependencies, run through npx, are exempt).
#
# Documented exceptions (NOT scanned): the deps-guard hook and its test fixtures
# (they *contain* pipe-to-shell strings in order to block them), and the
# published one-liner in README/docs (the bootstrap UX, pinned by release tag).

set -euo pipefail
cd "$(dirname "$0")/../.."

WORKFLOW_SOURCES=$(git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml' \
  'init-project/templates/core/.github/workflows/*.yml' \
  'init-project/templates/core/.github/workflows/*.yaml' \
  'init-project/templates/profiles/*/profile.json'; echo init-project/SKILL.md)
DOCKERFILES=$(git ls-files '*Dockerfile')

rc=0

echo "==> uses: must be SHA-pinned (owner/repo@<40-hex> # vX)"
for f in $WORKFLOW_SOURCES; do
  bad=$(grep -nE 'uses:[[:space:]]*[^[:space:]]+@' "$f" | grep -Ev '@[0-9a-f]{40}([[:space:]]|$)' || true)
  if [ -n "$bad" ]; then
    echo "pin-check: $f has tag-only (mutable) uses: pins:" >&2
    echo "$bad" >&2
    rc=1
  fi
done

echo "==> no pipe-to-shell (download, checksum-verify, then execute)"
for f in $WORKFLOW_SOURCES $DOCKERFILES; do
  bad=$(grep -nE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([[:space:]]|$)' "$f" || true)
  if [ -n "$bad" ]; then
    echo "pin-check: $f pipes a download into a shell:" >&2
    echo "$bad" >&2
    rc=1
  fi
done

echo "==> npx/uvx run an exact version (npx pkg@1.2.3, uvx --from 'pkg==1.2.3')"
NPX_SOURCES=$(git ls-files 'README.md' 'docs/*.md' 'bootstrap/*' 'init-project/*.md' \
  'init-project/reference/*.md' 'upgrade-project/*.md' 'init-project/templates/**' \
  | grep -v '/fixtures/' | grep -v 'deps-guard' || true)
for f in $NPX_SOURCES; do
  [ -f "$f" ] || continue
  bad=$(grep -noE 'npx( (--yes|-y))? [@a-z][^ `"]*' "$f" \
    | grep -vE '@[0-9]+\.[0-9]+\.[0-9]+' | grep -vE 'npx( (--yes|-y))? (eslint|tsc|vitest|prettier|playwright)' || true)
  bad+=$(grep -noE 'uvx [^ `"]+' "$f" | grep -v -- '--from' || true)
  if [ -n "$bad" ]; then
    echo "pin-check: $f runs an unpinned package:" >&2
    echo "$bad" >&2
    rc=1
  fi
done

[ "$rc" -eq 0 ] && echo "==> pin-check passed."
exit $rc
