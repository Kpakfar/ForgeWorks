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
#      in a file and be checksum-verified before execution.
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

[ "$rc" -eq 0 ] && echo "==> pin-check passed."
exit $rc
