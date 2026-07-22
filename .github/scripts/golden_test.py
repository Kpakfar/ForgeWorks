#!/usr/bin/env python3
"""Golden-fixture test for the deterministic renderer.

For every answers file in .github/fixtures/golden/*.json, render the project
tree with init-project/render.py and compare it byte-for-byte against the
committed expected tree in .github/fixtures/golden/expected/<name>/ -- file
set, file contents, symlink targets, and executable bits must all match.
Any drift is a failure with a diff.

    python3 .github/scripts/golden_test.py            # verify (CI)
    python3 .github/scripts/golden_test.py --update   # regenerate expected trees

Also cross-checks the load-bearing scalar values in each profile.json against
the matching YAML block in init-project/SKILL.md, so the two cannot drift
silently. Run from anywhere; paths resolve relative to the repo root.
"""

from __future__ import annotations

import difflib
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
FIXTURES = os.path.join(ROOT, ".github", "fixtures", "golden")
EXPECTED = os.path.join(FIXTURES, "expected")
RENDER = os.path.join(ROOT, "init-project", "render.py")
TEMPLATES = os.path.join(ROOT, "init-project", "templates")

SYNC_KEYS = ("language_version", "package_manager", "manifest_file",
             "install_command", "add_dep_command", "qa_command", "fix_command",
             "e2e_command", "test_runner", "lint_tool", "format_tool", "type_tool")


def tree_entries(root: str) -> dict[str, tuple[str, object]]:
    """relpath -> ("link", target) | ("file", (bytes, is_executable))."""
    entries: dict[str, tuple[str, object]] = {}
    for dirpath, dirnames, names in os.walk(root):
        dirnames.sort()
        for name in sorted(names):
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, root)
            if os.path.islink(path):
                entries[rel] = ("link", os.readlink(path))
            else:
                with open(path, "rb") as f:
                    data = f.read()
                is_exec = bool(os.stat(path).st_mode & stat.S_IXUSR)
                entries[rel] = ("file", (data, is_exec))
    return entries


def diff_text(rel: str, want: bytes, got: bytes) -> str:
    try:
        lines = difflib.unified_diff(
            want.decode("utf-8").splitlines(keepends=True),
            got.decode("utf-8").splitlines(keepends=True),
            fromfile=f"expected/{rel}", tofile=f"rendered/{rel}")
        return "".join(list(lines)[:60])
    except UnicodeDecodeError:
        return f"binary file differs ({len(want)} vs {len(got)} bytes)"


def compare(expected_dir: str, rendered_dir: str) -> list[str]:
    want, got = tree_entries(expected_dir), tree_entries(rendered_dir)
    problems: list[str] = []
    problems += [f"missing from render: {rel}" for rel in sorted(want.keys() - got.keys())]
    problems += [f"unexpected extra file: {rel}" for rel in sorted(got.keys() - want.keys())]
    for rel in sorted(want.keys() & got.keys()):
        (wkind, wval), (gkind, gval) = want[rel], got[rel]
        if wkind != gkind:
            problems.append(f"{rel}: expected {wkind}, got {gkind}")
        elif wkind == "link":
            if wval != gval:
                problems.append(f"{rel}: symlink target {gval!r} != expected {wval!r}")
        else:
            wdata, wexec = wval  # type: ignore[misc]
            gdata, gexec = gval  # type: ignore[misc]
            if wdata != gdata:
                problems.append(f"{rel}: content drift\n{diff_text(rel, wdata, gdata)}")
            if wexec != gexec:
                problems.append(f"{rel}: executable bit is {gexec}, expected {wexec}")
    return problems


def render_fixture(fixture: str, out_dir: str) -> None:
    with open(fixture, encoding="utf-8") as f:
        language = json.load(f)["stack"]["language"]
    subprocess.run(
        [sys.executable, RENDER,
         "--answers", fixture,
         "--core", os.path.join(TEMPLATES, "core"),
         "--profile", os.path.join(TEMPLATES, "profiles", language),
         "--out", out_dir],
        check=True, cwd=ROOT)


def profile_sync_check() -> list[str]:
    """The load-bearing profile.json scalars must appear verbatim in the
    matching SKILL.md <language-profiles> YAML block."""
    with open(os.path.join(ROOT, "init-project", "SKILL.md"), encoding="utf-8") as f:
        skill = f.read()
    problems: list[str] = []
    for lang in ("python", "typescript", "go", "rust"):
        with open(os.path.join(TEMPLATES, "profiles", lang, "profile.json"),
                  encoding="utf-8") as f:
            prof = json.load(f)
        for key in SYNC_KEYS:
            needle = f'{key}: "{prof[key]}"'
            if needle not in skill:
                problems.append(f"{lang}/profile.json: `{needle}` not found in "
                                "SKILL.md <language-profiles> -- the two drifted")
    return problems


# Cross-profile parity contract: every profile must carry evidence of each
# quality capability. (relpath, needle) -- needle None means "file exists".
# race/sanitizer applies only where the language has one (Go: -race).
PARITY_CONTRACT = {
    "python": [
        ("scripts/qa.sh", "linecap.sh"),            # line cap
        ("scripts/qa.sh", "ruff format --check"),   # format check
        ("scripts/qa.sh", "ruff check"),             # lint as error
        ("scripts/qa.sh", "mypy"),                  # type check
        ("scripts/qa.sh", 'pytest -m "not e2e"'),   # unit gate
        ("scripts/e2e.sh", "pytest"),               # e2e runner
    ],
    "typescript": [
        ("eslint.config.js", "max-lines"),          # line cap (lint rule)
        ("package.json", "prettier --check"),       # format check
        ("package.json", "eslint ."),               # lint as error
        ("package.json", "tsc --noEmit"),           # type check
        ("package.json", "vitest run"),             # unit gate
        ("package.json", "playwright test"),        # e2e runner
    ],
    "go": [
        ("scripts/qa.sh", "linecap.sh"),
        ("scripts/qa.sh", "gofmt -l"),
        ("scripts/qa.sh", "golangci-lint run"),
        ("scripts/qa.sh", "go vet"),
        ("scripts/qa.sh", "go test -race ./..."),   # unit gate + race detector
        ("scripts/e2e.sh", "go test -race -tags e2e"),
    ],
    "rust": [
        ("scripts/qa.sh", "linecap.sh"),
        ("scripts/qa.sh", "cargo fmt --check"),
        ("scripts/qa.sh", "-D warnings"),           # clippy, warnings are errors
        ("scripts/qa.sh", "cargo check"),
        ("scripts/qa.sh", "cargo test"),
        ("scripts/e2e.sh", "cargo test"),
    ],
}


def parity_check() -> list[str]:
    """Every language profile must prove every capability in the contract."""
    problems: list[str] = []
    profiles = sorted(os.listdir(os.path.join(TEMPLATES, "profiles")))
    for lang in profiles:
        if lang not in PARITY_CONTRACT:
            problems.append(f"{lang}: profile has no PARITY_CONTRACT entry -- "
                            "add one before shipping the profile")
    for lang, rows in PARITY_CONTRACT.items():
        base = os.path.join(TEMPLATES, "profiles", lang)
        for relpath, needle in rows:
            path = os.path.join(base, relpath)
            if not os.path.isfile(path):
                problems.append(f"{lang}: parity evidence file missing: {relpath}")
                continue
            with open(path, encoding="utf-8") as f:
                content = f.read()
            if needle is not None and needle not in content:
                problems.append(f"{lang}/{relpath}: parity evidence missing: {needle!r}")
    return problems


def main() -> int:
    update = "--update" in sys.argv[1:]
    fixtures = sorted(f for f in os.listdir(FIXTURES) if f.endswith(".json"))
    if not fixtures:
        print("golden_test: no fixtures found", file=sys.stderr)
        return 1
    rc = 0
    for problem in profile_sync_check():
        print(f"FAIL [profile-sync] {problem}")
        rc = 1
    for problem in parity_check():
        print(f"FAIL [parity] {problem}")
        rc = 1
    for fixture in fixtures:
        name = fixture[:-len(".json")]
        expected_dir = os.path.join(EXPECTED, name)
        with tempfile.TemporaryDirectory() as tmp:
            rendered = os.path.join(tmp, "proj")
            try:
                render_fixture(os.path.join(FIXTURES, fixture), rendered)
            except subprocess.CalledProcessError:
                print(f"FAIL [{name}] render.py exited non-zero")
                rc = 1
                continue
            if update:
                if os.path.isdir(expected_dir):
                    shutil.rmtree(expected_dir)
                shutil.copytree(rendered, expected_dir, symlinks=True)
                print(f"ok   [{name}] expected tree regenerated")
                continue
            if not os.path.isdir(expected_dir):
                print(f"FAIL [{name}] no expected tree at {expected_dir} "
                      "(run with --update and commit the result)")
                rc = 1
                continue
            problems = compare(expected_dir, rendered)
            if problems:
                print(f"FAIL [{name}] {len(problems)} drift(s):")
                for problem in problems:
                    print(f"  - {problem}")
                rc = 1
            else:
                print(f"ok   [{name}] byte-for-byte match "
                      f"({len(tree_entries(expected_dir))} entries)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
