#!/usr/bin/env bash
# release_check.sh -- the published one-liner must point at something that exists.
#
# Fails if:
#   1. any pinned release ref (the raw URLs and degit calls in README/docs, the
#      REF default in bootstrap/install.sh, the reconcile ref in
#      upgrade-project/SKILL.md, TEMPLATE_VERSION in init-project/render.py)
#      is not v<VERSION>, or
#   2. any owner/ForgeWorks slug is not the REPO default in bootstrap/install.sh
#      (and, when EXPECT_REPO is set, that default is not EXPECT_REPO -- CI passes
#      the repository it runs in, so a transferred repo fails here), or
#   3. with --remote-tag: the tag v<VERSION> is not on the remote. A raw URL
#      for a tag that was never pushed returns 404.
#
# Check 3 is a separate mode because a release merges first and tags second:
# the commit that bumps VERSION has no tag yet. See .github/workflows/release-tag.yml.
#
# Not scanned: docs/superpowers/ (dated plans; they record the refs of their day).

set -euo pipefail
cd "$(dirname "$0")/../.."

REMOTE_TAG=0
[ "${1:-}" = "--remote-tag" ] && REMOTE_TAG=1

VERSION="v$(tr -d '[:space:]' < VERSION)"
rc=0

echo "==> pinned release refs must be ${VERSION}"
pins=$(git grep -noE \
  -e 'ForgeWorks/v[0-9]+\.[0-9]+\.[0-9]+' \
  -e 'ForgeWorks[^[:space:]]*#v[0-9]+\.[0-9]+\.[0-9]+' \
  -e 'BRANCH:-v[0-9]+\.[0-9]+\.[0-9]+' \
  -e 'TEMPLATE_VERSION = "v[0-9]+\.[0-9]+\.[0-9]+' \
  -e 'released tag \(`v[0-9]+\.[0-9]+\.[0-9]+' \
  -- . ':!docs/superpowers' || true)
if [ -z "$pins" ]; then
  echo "release-check: found no pinned release refs -- the patterns no longer match." >&2
  rc=1
fi
bad=$(printf '%s\n' "$pins" | grep -v -E "${VERSION//./\\.}\$" || true)
if [ -n "$bad" ]; then
  echo "release-check: these pins are not ${VERSION} (see AGENTS.md <release-process>):" >&2
  echo "$bad" >&2
  rc=1
fi

REPO=$(sed -nE 's/^REPO="\$\{REPO:-([^}]+)\}"$/\1/p' bootstrap/install.sh)
if [ -z "$REPO" ]; then
  echo "release-check: cannot read the REPO default from bootstrap/install.sh." >&2
  exit 1
fi
if [ -n "${EXPECT_REPO:-}" ] && [ "$REPO" != "$EXPECT_REPO" ]; then
  echo "release-check: bootstrap/install.sh defaults to ${REPO}, but this repository is ${EXPECT_REPO}." >&2
  rc=1
fi

echo "==> owner/ForgeWorks slugs must be ${REPO}"
bad=$(git grep -noE \
  -e '(github\.com|githubusercontent\.com)/[^/[:space:]]+/ForgeWorks' \
  -e 'degit(@[0-9.]+)? [^/[:space:]]+/ForgeWorks' \
  -- . ':!docs/superpowers' | grep -v -E "[/ ]${REPO}\$" || true)
if [ -n "$bad" ]; then
  echo "release-check: these slugs are not ${REPO}:" >&2
  echo "$bad" >&2
  rc=1
fi

if [ "$REMOTE_TAG" -eq 1 ]; then
  echo "==> tag ${VERSION} must be on the remote"
  if [ "${GITHUB_REF_TYPE:-}" = "tag" ] && [ "${GITHUB_REF_NAME:-}" != "$VERSION" ]; then
    echo "release-check: pushed tag ${GITHUB_REF_NAME} does not match VERSION (${VERSION})." >&2
    rc=1
  fi
  if [ -z "$(git ls-remote --tags origin "refs/tags/${VERSION}")" ]; then
    echo "release-check: VERSION says ${VERSION}, but that tag is not on the remote." >&2
    echo "The published one-liner returns 404 until you run:" >&2
    echo "  git tag ${VERSION} && git push origin ${VERSION}" >&2
    rc=1
  fi
fi

[ "$rc" -eq 0 ] && echo "==> release-check passed."
exit $rc
