#!/usr/bin/env python3
"""Fail when the same block of source appears in two or more files.

DRY has a rule in `AGENTS.md` `<commands>` + the `iteration` skill, but a rule nobody
measures is a suggestion. This is the measurement: every 6-line window of
every source file, normalized and hashed. A window found in two different files
is copied code, copied markup, or -- most often in an agent-built project -- the
same paragraph of justification restated in five docstrings.

Normalization strips what varies without changing the shape: comments, blank
lines, import lines, string literals, numbers, and runs of whitespace. Import
lines go because two files that need the same modules share a header no one
can extract. So two functions that
differ only in their strings still count as duplicates, which is the point.

    python3 scripts/dup_check.py             # check, exit 1 on a finding
    python3 scripts/dup_check.py --list      # print every finding, exit 0
    python3 scripts/dup_check.py --baseline  # accept today's findings, once

`--baseline` REFUSES to add hashes once a baseline exists -- it may only drop
ones you have fixed. Without that, the gate has a one-command bypass: hit a red
dup-check, re-run --baseline, CI goes green, and the duplication you just
introduced is now "accepted". Growing it needs `--baseline --force` plus a
`dup-change: <why>` line in the commit body, which is a decision someone can
see in review rather than a silent capitulation.

Two escape hatches, and the difference matters:

`.dup-ignore` (path globs, `#` for comments) exempts a file wholesale -- use it
only for a directory whose repetition is inherent, like a test tree where a
repeated arrange block reads better than a shared helper.

`.dup-baseline` (written by `--baseline`) records the HASHES of the blocks that
were already duplicated when you adopted the gate. Those stop failing; anything
new fails, INCLUDING new duplication inside a file the baseline already covers.
Edit a baselined block and its hash changes, so touching old duplication asks
you to fix it. That is the ratchet: a path exemption is permanent, a baseline
entry decays. Prefer the baseline; the file should only ever shrink.
"""

from __future__ import annotations

import fnmatch
import hashlib
import os
import re
import sys

WINDOW = 6
BASELINE = ".dup-baseline"
SUFFIXES = {{SOURCE_SUFFIXES}}
SKIP_DIRS = {
    ".git",
    "node_modules",
    "__pycache__",
    ".venv",
    "venv",
    "dist",
    "build",
    ".next",
    ".astro",
    "target",
    "vendor",
    ".mypy_cache",
    ".ruff_cache",
    ".pytest_cache",
    "coverage",
    ".claude",
}
LINE_COMMENT = re.compile(r"^\s*(#|//|\*|/\*|--|<!--)")
IMPORT = re.compile(r"^\s*(import\s|from\s+\S+\s+import\s|use\s|extern\s+crate\s|require\()")
LITERAL = re.compile(r'"[^"]*"|\'[^\']*\'|`[^`]*`')
NUMBER = re.compile(r"\b\d[\d_.]*\b")
WHITESPACE = re.compile(r"\s+")


def baseline() -> set[str]:
    if not os.path.exists(BASELINE):
        return set()
    with open(BASELINE, encoding="utf-8") as f:
        return {ln.strip() for ln in f if ln.strip() and not ln.startswith("#")}


def ignores() -> list[str]:
    if not os.path.exists(".dup-ignore"):
        return []
    with open(".dup-ignore", encoding="utf-8") as f:
        return [ln.strip() for ln in f if ln.strip() and not ln.startswith("#")]


def sources(patterns: list[str]) -> list[str]:
    out = []
    for root, dirs, files in os.walk("."):
        # SKIP_DIRS is the whole rule -- do NOT also skip every dotted dir.
        # Production source can live in one, and a gate that cannot see a
        # directory is worse than no gate: it reports OK.
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if not name.endswith(tuple(SUFFIXES)):
                continue
            path = os.path.normpath(os.path.join(root, name))
            if any(fnmatch.fnmatch(path, p) for p in patterns):
                continue
            out.append(path)
    return sorted(out)


def normalize(path: str) -> list[tuple[str, int]]:
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            raw = f.read().split("\n")
    except OSError:
        return []
    kept = []
    for lineno, line in enumerate(raw, 1):
        if not line.strip() or LINE_COMMENT.match(line) or IMPORT.match(line):
            continue
        text = WHITESPACE.sub(" ", NUMBER.sub("N", LITERAL.sub("S", line))).strip()
        if len(text) < 8:  # braces, `end`, single tokens: shape, not substance
            continue
        kept.append((text, lineno))
    return kept


def main(argv: list[str]) -> int:
    listing = argv[:1] == ["--list"]
    writing = argv[:1] == ["--baseline"]
    forcing = writing and "--force" in argv[1:]
    known = set() if (listing or writing) else baseline()
    patterns = ignores()
    windows: dict[str, list[tuple[str, int]]] = {}
    for path in sources(patterns):
        lines = normalize(path)
        for i in range(len(lines) - WINDOW + 1):
            body = "\n".join(t for t, _ in lines[i : i + WINDOW])
            windows.setdefault(hashlib.sha256(body.encode()).hexdigest(), []).append(
                (path, lines[i][1])
            )
    shared = {d: h for d, h in windows.items() if len({p for p, _ in h}) > 1}
    if writing:
        # A ratchet only ratchets if it cannot be wound backwards.
        previous = baseline()
        added = set(shared) - previous
        if previous and added and not forcing:
            print(
                f"::error::--baseline would ACCEPT {len(added)} newly duplicated "
                f"block(s). A baseline records what predated the gate; it is not "
                f"a way to make today's duplication pass. Extract them, or -- if "
                f"they are genuinely unavoidable -- re-run with --force AND put a "
                f"'dup-change: <why>' line in the commit body so the decision is "
                f"visible in review."
            )
            for digest in sorted(added)[:5]:
                where = ", ".join(f"{p}:{n}" for p, n in sorted(windows[digest])[:2])
                print(f"  would accept: {where}")
            return 1
        with open(BASELINE, "w", encoding="utf-8") as f:
            f.write(
                "# Blocks already duplicated when the gate was adopted, by hash.\n"
                "# Anything NOT listed here fails. Editing a listed block changes its\n"
                "# hash, so touching old duplication asks you to fix it. Only shrinks.\n"
            )
            f.write("".join(f"{d}\n" for d in sorted(shared)))
        print(f"dup-check: baselined {len(shared)} existing duplicate block(s) -> {BASELINE}")
        return 0
    findings = {}
    for digest, hits in shared.items():
        if digest in known:
            continue
        findings.setdefault(tuple(sorted({p for p, _ in hits})), []).append(hits[0])
    if not findings:
        extra = f", {len(known)} baselined" if known else ""
        print(f"dup-check: OK ({len(windows)} windows, no new block shared between files{extra})")
        return 0
    for files, hits in sorted(findings.items(), key=lambda kv: -len(kv[1])):
        where = ", ".join(f"{p}:{n}" for p, n in sorted(hits)[:3])
        print(
            f"::error::{len(hits)} block(s) of {WINDOW}+ lines shared between "
            f"{len(files)} files: {' | '.join(files)} (first at {where})"
        )
    total = sum(len(h) for h in findings.values())
    print(
        f"dup-check: {total} duplicated block(s) across {len(findings)} file group(s). "
        "Extract to one home, or -- if this is framework boilerplate that cannot be "
        "factored out -- add the path to .dup-ignore with a reason."
    )
    return 0 if listing else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
