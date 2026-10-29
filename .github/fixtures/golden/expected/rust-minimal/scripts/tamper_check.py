#!/usr/bin/env python3
"""Test-tamper guard: a changed or deleted test or gate needs a stated reason.

Compares HEAD against TAMPER_BASE: the pull request's base branch, or on a
push the commit the push started from (qa.yml sets it per event; locally it
defaults to origin/main, fallback main). A "test-change:" line somewhere in
the commit messages of the range is required when the range:

- modifies, deletes, or renames a file matching the profile's test-path pattern;
- changes a gate: a workflow, a QA runner, a gate script, a hook, the dup
  baseline or ignore list, or a lint config file;
- removes a test or an assertion from a source file, for a language whose
  unit tests live inside source files (the profile's inline-test pattern).

Added tests are always fine. The manifest is not a gate file here, so adding
a dependency needs no reason; its lint and test settings change through
review. Enforces the AGENTS.md hard rule mechanically. Run locally or in CI:

    python3 scripts/tamper_check.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

TEST_PATH_RE = re.compile(r"^tests/")
INLINE_TEST = r"#\[test\]|#\[cfg\(test\)\]|\bassert(_eq|_ne)?!"
INLINE_TEST_RE = re.compile(INLINE_TEST) if INLINE_TEST else None
GATE_PATH_RE = re.compile(
    r"^\.github/workflows/"
    r"|^scripts/(qa|fix|e2e|linecap)\.sh$"
    r"|^scripts/(tamper|dup|features|line)_check\.py$"
    r"|^\.dup-(baseline|ignore)$"
    r"|^\.claude/hooks/|^\.claude/settings\.json$"
    r"|^\.pre-commit-config\.ya?ml$|(^|/)eslint\.config\.[cm]?[jt]s$"
    r"|^\.golangci\.ya?ml$|^(\.)?(ruff|clippy|rustfmt)\.toml$"
)
REASON_RE = re.compile(r"^\s*test-change:\s*\S", re.MULTILINE)
NO_COMMIT = re.compile(r"^0+$")


def _git(*args: str) -> str:
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def resolve_base() -> str | None:
    base = os.environ.get("TAMPER_BASE", "").strip() or "origin/main"
    if NO_COMMIT.match(base):
        return None  # the first push of a new branch: nothing to compare with
    for candidate in (base, "main"):
        try:
            return _git("merge-base", candidate, "HEAD").strip()
        except subprocess.CalledProcessError:
            continue
    return None


def removed_inline_tests(merge_base: str, path: str) -> bool:
    diff = _git("diff", "-U0", f"{merge_base}..HEAD", "--", path)
    removed = [
        ln[1:] for ln in diff.splitlines() if ln.startswith("-") and not ln.startswith("---")
    ]
    return any(INLINE_TEST_RE.search(ln) for ln in removed) if INLINE_TEST_RE else False


def touched_files(merge_base: str) -> list[tuple[str, list[str]]]:
    touched = []
    for line in _git("diff", "--name-status", f"{merge_base}..HEAD").splitlines():
        if not line:
            continue
        fields = line.split("\t")
        status, kind = fields[0], fields[0][:1]
        # R*/C* lines carry BOTH paths, and either can hide a tampered test
        # (`git mv tests/foo_test.py tests/foo.py` + edit): flag on any match.
        paths = fields[1:3] if kind in ("R", "C") else fields[1:2]
        if kind not in ("M", "D", "R", "C"):
            continue  # an added file weakens nothing
        hits = [p for p in paths if TEST_PATH_RE.search(p)]
        if hits:
            touched.append((status, hits))
            continue
        gates = [p for p in paths if GATE_PATH_RE.search(p)]
        if gates:
            touched.append((f"{status} gate", gates))
        elif kind in ("M", "R") and removed_inline_tests(merge_base, paths[-1]):
            touched.append((f"{status} inline test", paths[-1:]))
    return touched


def main() -> int:
    merge_base = resolve_base()
    if merge_base is None:
        print("tamper-check: SKIP (no base to compare with)")
        return 0
    if merge_base == _git("rev-parse", "HEAD").strip():
        print("tamper-check: OK (no commits ahead of base)")
        return 0
    touched = touched_files(merge_base)
    if not touched:
        print("tamper-check: OK (no existing test or gate modified or deleted)")
        return 0
    messages = _git("log", "--format=%B", f"{merge_base}..HEAD")
    if REASON_RE.search(messages):
        print(f"tamper-check: OK ({len(touched)} test/gate change(s), reason stated)")
        return 0
    print("tamper-check: FAIL -- existing tests or gates changed with no stated reason.")
    for status, paths in touched:
        print(f"  - {status}\t{' -> '.join(paths)}")
    print('State the reason with a "test-change: <why>" line in a commit body.')
    return 1


if __name__ == "__main__":
    sys.exit(main())
