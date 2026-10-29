#!/usr/bin/env python3
"""Fail when a rule the template STATES and a gate that ENFORCES it disagree.

Every bug found in the v4.1 field review was the same shape: one fact written
down twice, drifting apart.

    AGENTS.md <context> said "20K"     while docs-budget said 20000 and the
                                       real file sat at 19,977
    <context> banned whole-file reads  while nothing offered a cheaper read
    the iteration skill said           while docs-budget capped
      "half a context window"            nothing at all
    dup_check.py's docstring cited     a block that does not exist
      <architecture-discipline>

None of those needed a real project to surface. They were checkable the whole
time, and nothing checked them. This is that check.

The rule it enforces is simple: **a gate owns its number; prose points at the
gate.** So the fix for a failure here is almost never "update the other copy" --
it is "delete the copy and name the gate instead."

    python3 .github/scripts/rule_check.py [rendered-tree ...]

With no arguments it renders every golden fixture and checks each tree.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FIXTURES = os.path.join(REPO, ".github", "fixtures", "golden")

# Prose files whose claims must not restate a gate's number.
# Only files the TEMPLATE authors. A project fills SECURITY.md and gotchas.md
# with its own numbers ("caps the message at 2000 code points"), which are not
# restatements of anything -- checking them would trade a real bug for noise.
# This runs against freshly rendered trees, so what it sees is template prose.
PROSE = (
    "AGENTS.md",
    ".claude/skills/iteration/SKILL.md",
    ".claude/skills/tech-debt/SKILL.md",
    ".claude/skills/security-review/SKILL.md",
    "docs/SECURITY.md",
    "docs/gotchas.md",
    ".claude/skills/iteration/reference/dispatch.md",
    ".claude/agents/reviewer.md",
    "docs/plans/README.md",
    "docs/probes/README.md",
)
# The generator's own prose restates caps too -- the brownfield path is where a
# transcribed number rots quietest, because nobody re-reads an upgrade skill.
REPO_PROSE = ("init-project/SKILL.md", "init-project/reference/renderer-rules.md",
              "upgrade-project/SKILL.md", "AGENTS.md")
# A number this large in prose, near a budget word, is a restated cap.
BUDGET_WORD = re.compile(
    r"(cap|budget|limit|chars|characters|tokens|lines)", re.I
)
BIG_NUMBER = re.compile(r"\b(\d{3,})\s*(?:K\b|chars|characters|tokens|lines)?", re.I)
K_NUMBER = re.compile(r"\b(\d+)K\b")
# Paths named in prose must exist in the tree.
PATH_REF = re.compile(r"`((?:scripts|docs|\.claude|\.github)/[A-Za-z0-9_./<>*-]+)`")


def gate_numbers(tree: str) -> set[int]:
    """Every cap the CI gates actually enforce."""
    qa = os.path.join(tree, ".github", "workflows", "qa.yml")
    if not os.path.exists(qa):  # called with a template dir, not a rendered tree
        qa = os.path.join(tree, ".github", "workflows", "qa.yml")
    nums: set[int] = set()
    if os.path.exists(qa):
        text = open(qa, encoding="utf-8").read()
        for m in re.finditer(r"check\s+\S+\s+(\d+)|-gt\s+\"?(\d+)", text):
            nums.add(int(m.group(1) or m.group(2)))
    dup = os.path.join(tree, "scripts", "dup_check.py")
    if os.path.exists(dup):
        m = re.search(r"^WINDOW = (\d+)", open(dup, encoding="utf-8").read(), re.M)
        if m:
            nums.add(int(m.group(1)))
    return nums


def check_tree(tree: str, label: str) -> list[str]:
    problems: list[str] = []
    gates = gate_numbers(tree)
    if not gates:
        problems.append(f"{label}: found no enforced numbers -- is qa.yml missing?")

    for rel in PROSE:
        path = os.path.join(tree, rel)
        if not os.path.exists(path):
            # Silently skipping a renamed file exempts all its prose -- failing
            # in the direction of passing, which is what this file exists to
            # stop. Frontend-only files are the one legitimate absence.
            if rel.startswith("docs/design") or rel.startswith(".claude/agents"):
                continue  # frontend-only / claude-code-roster-only files
            problems.append(f"{label}: {rel} is in PROSE but the rendered tree "
                            f"does not have it. Renamed? Update PROSE -- do not "
                            f"let its rules go unchecked.")
            continue
        for lineno, line in enumerate(open(path, encoding="utf-8"), 1):
            if not BUDGET_WORD.search(line):
                continue
            found = {int(m.group(1)) for m in BIG_NUMBER.finditer(line)}
            found |= {int(m.group(1)) * 1000 for m in K_NUMBER.finditer(line)}
            clash = found & gates
            if clash:
                problems.append(
                    f"{label}: {rel}:{lineno} states {sorted(clash)}, which a "
                    f"gate also owns. Usually: delete it and name the gate. But "
                    f"a project's own prose can legitimately mention a number "
                    f"that happens to equal a cap (\"caps the message at 2000 "
                    f"code points\") -- if so, reword so the two do not read as "
                    f"the same fact. Two copies of one fact drift; a coincidence "
                    f"does not."
                )

    # Every path prose points at must exist. A rule that cites a file nobody
    # wrote is indistinguishable from a rule nobody follows.
    for rel in PROSE:
        path = os.path.join(tree, rel)
        if not os.path.exists(path):
            continue
        for lineno, line in enumerate(open(path, encoding="utf-8"), 1):
            for m in PATH_REF.finditer(line):
                ref = m.group(1)
                if any(c in ref for c in "<>*"):
                    continue  # a pattern, not a path
                if re.search(r"frontend|only if|only when|if present", line, re.I):
                    continue  # prose marks it conditional; absence is correct
                if not os.path.exists(os.path.join(tree, ref)):
                    problems.append(
                        f"{label}: {rel}:{lineno} points at `{ref}`, "
                        f"which the rendered project does not have."
                    )
    return problems


def check_repo() -> list[str]:
    """Guard the GENERATOR, not just what it emits.

    The last two defects lived here, not in a rendered tree: a profile.json key
    the renderer expected and two profiles lacked, and a second copy of profile
    values inside render_smoke.py. A gate that only reads output cannot see
    either.
    """
    problems: list[str] = []
    render_path = os.path.join(REPO, "init-project", "render.py")
    qa_path = os.path.join(REPO, "init-project", "templates", "core",
                           ".github", "workflows", "qa.yml")
    render = open(render_path, encoding="utf-8").read()
    qa = open(qa_path, encoding="utf-8").read()

    # Each pattern is asserted SEPARATELY. A drift gate that silently stops
    # finding the thing it guards fails in the direction of passing, which is
    # the exact failure mode this file exists to prevent.
    # Same unit too: render.py counts UTF-8 bytes, the job counts with wc -c.
    m = re.search(r'relpath == "AGENTS\.md" and len\(text\.encode\("utf-8"\)\) > (\d+)', render)
    g = re.search(r"^\s*check AGENTS\.md (\d+)", qa, re.M)
    if not re.search(r'size=\$\(wc -c < "\$f"\)', qa):
        problems.append(f"{qa_path}: docs-budget no longer counts with `wc -c`; "
                        "render.py counts bytes, so the two units drifted.")
    if not m:
        problems.append(f"rotted: no AGENTS.md char cap found in {render_path} "
                        f"(pattern: 'relpath == \"AGENTS.md\" and len(text.encode(\"utf-8\")) > N'). "
                        f"Fix the pattern -- do not delete the check.")
    if not g:
        problems.append(f"rotted: no AGENTS.md char cap found in {qa_path} "
                        f"(pattern: 'check AGENTS.md N'). "
                        f"Fix the pattern -- do not delete the check.")
    if m and g and m.group(1) != g.group(1):
        problems.append(
            f"render.py fails AGENTS.md over {m.group(1)} bytes but the shipped "
            f"docs-budget job uses {g.group(1)}. A project would render fine and "
            f"then fail its own CI, or the reverse."
        )

    # The generator's own prose is checked against the caps it ships.
    gates = gate_numbers(os.path.join(REPO, "init-project", "templates", "core"))
    for rel in REPO_PROSE:
        path = os.path.join(REPO, rel)
        if not os.path.exists(path):
            continue
        for lineno, line in enumerate(open(path, encoding="utf-8"), 1):
            if not BUDGET_WORD.search(line):
                continue
            found = {int(m.group(1)) for m in BIG_NUMBER.finditer(line)}
            found |= {int(m.group(1)) * 1000 for m in K_NUMBER.finditer(line)}
            clash = found & gates
            if clash:
                problems.append(
                    f"{rel}:{lineno} transcribes {sorted(clash)} from the shipped "
                    f"CI gates. Point at the job instead -- a number copied into "
                    f"a skill nobody re-reads is the quietest kind of drift."
                )

    # Every profile must carry every scalar the renderer substitutes. This is
    # what would have caught {{SOURCE_SUFFIXES}} landing in four profile.json
    # files while two of them were never updated.
    sys.path.insert(0, os.path.join(REPO, "init-project"))
    try:
        from render_schema import PROFILE_LISTS, PROFILE_SCALARS  # noqa: PLC0415
    except ImportError as exc:  # pragma: no cover
        return problems + [f"cannot import render_schema to check profiles: {exc}"]
    profiles_dir = os.path.join(REPO, "init-project", "templates", "profiles")
    for lang in sorted(os.listdir(profiles_dir)):
        pj = os.path.join(profiles_dir, lang, "profile.json")
        if not os.path.exists(pj):
            continue
        prof = json.load(open(pj, encoding="utf-8"))
        for key in PROFILE_SCALARS + PROFILE_LISTS:
            if key not in prof:
                problems.append(
                    f"profiles/{lang}/profile.json is missing {key!r}, which the "
                    f"renderer substitutes. Every profile carries every key, or "
                    f"that language renders a leftover placeholder."
                )
    return problems


def main(argv: list[str]) -> int:
    problems: list[str] = []
    problems += check_repo()
    if argv:
        for tree in argv:
            problems += check_tree(tree, os.path.basename(tree.rstrip("/")))
    else:
        names = sorted(f[:-5] for f in os.listdir(FIXTURES) if f.endswith(".json"))
        with tempfile.TemporaryDirectory() as tmp:
            for name in names:
                answers = os.path.join(FIXTURES, f"{name}.json")
                lang = json.load(open(answers, encoding="utf-8"))["stack"]["language"]
                out = os.path.join(tmp, name)
                r = subprocess.run(
                    [sys.executable, os.path.join(REPO, "init-project", "render.py"),
                     "--answers", answers,
                     "--core", os.path.join(REPO, "init-project", "templates", "core"),
                     "--profile", os.path.join(REPO, "init-project", "templates", "profiles", lang),
                     "--out", out],
                    capture_output=True, text=True)
                if r.returncode:
                    problems.append(f"{name}: render failed: {r.stderr.strip()[:200]}")
                    continue
                problems += check_tree(out, name)
    for p in problems:
        print(f"::error::{p}")
    if problems:
        print(f"\nrule-check: {len(problems)} rule/gate disagreement(s).")
        return 1
    print("rule-check: OK (no rule restates a number its gate owns; every cited path exists)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
