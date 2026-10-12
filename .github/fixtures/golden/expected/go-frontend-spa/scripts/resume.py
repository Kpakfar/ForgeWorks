#!/usr/bin/env python3
"""Print what a fresh session needs to pick the work back up. This is `go`.

    python3 scripts/resume.py           # the brief
    python3 scripts/resume.py --check   # CI: would `go` work right now?

Nothing here is stored. Every pointer is read from the file that owns it --
the in-progress entry in docs/features.json (status, phase, next), its plan
file, and the git branch -- and the pointers are cross-checked. When they
disagree this REFUSES to print a brief: a resume built on contradictory
pointers resumes the wrong work confidently.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from backlog import blocked_by  # noqa: E402

FEATURES = os.path.join("docs", "features.json")
PLANS = os.path.join("docs", "plans")
NEXT_PHASE = {"grill": "RED", "red": "GREEN", "green": "REVIEW", "review": "REPLAN"}


def git(*args: str) -> str:
    try:
        r = subprocess.run(("git",) + args, capture_output=True, text=True, timeout=10)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def find_plan(fid: str) -> str:
    direct = os.path.join(PLANS, f"{fid}.md")
    if os.path.exists(direct):
        return direct
    if not os.path.isdir(PLANS):
        return ""
    for name in sorted(os.listdir(PLANS)):
        if name.lower().startswith(fid.lower()) and name.endswith(".md"):
            return os.path.join(PLANS, name)
    return ""


def collect() -> tuple[dict, list[str]]:
    """Read every pointer from the file that owns it. Never guess."""
    problems: list[str] = []
    state: dict = {}
    try:
        with open(FEATURES, encoding="utf-8") as f:
            feats = json.load(f)["features"]
    except (OSError, KeyError, json.JSONDecodeError) as exc:
        return {}, [f"cannot read {FEATURES}: {exc}"]

    live = [ft for ft in feats if ft["status"] == "in-progress"]
    if len(live) > 1:
        ids = ", ".join(ft["id"] for ft in live)
        problems.append(
            f"{len(live)} features are in-progress ({ids}). `go` cannot choose. "
            f"Finish or park one -- an abandoned in-progress entry is the usual cause."
        )
        return state, problems
    if not live:
        todos = [ft for ft in feats if ft["status"] == "todo"]
        todo = next((ft for ft in todos if not blocked_by(ft, feats)), None)
        state["idle"] = True
        branch = git("rev-parse", "--abbrev-ref", "HEAD")
        closed = [ft["id"] for ft in feats if ft["status"] == "done"]
        if branch.startswith("feat/"):
            state["unmerged"] = next((i for i in closed if i.lower() in branch.lower()), None)
            state["branch"] = branch
        state["blocked"] = [ft["id"] for ft in todos] if not todo else []
        state["next_todo"] = todo["id"] if todo else None
        state["next_title"] = todo["title"] if todo else None
        return state, problems

    ft = live[0]
    state["feature"] = ft
    phase = ft.get("phase")
    if phase not in NEXT_PHASE:
        problems.append(
            f"{ft['id']} is in-progress but its `phase` is {phase!r}. Set it: "
            f"`python3 scripts/feature.py {ft['id']} phase=<grill|red|green|review>`."
        )
    state["phase"] = phase
    state["next"] = ft.get("next")
    plan = find_plan(ft["id"])
    if plan:
        state["plan"] = plan
    elif phase != "grill":
        problems.append(
            f"{ft['id']} is past GRILL but has no plan under {PLANS}/. Either it "
            f"was deleted early, or the feature never went through GRILL."
        )
    branch = git("rev-parse", "--abbrev-ref", "HEAD")
    state["branch"] = branch
    if branch.startswith("feat/") and ft["id"].lower() not in branch.lower():
        problems.append(
            f"on branch {branch!r}, which does not name {ft['id']}. Either you are on "
            f"the wrong branch or the wrong feature is marked in-progress."
        )
    state["dirty"] = bool(git("status", "--porcelain"))
    return state, problems


def brief(state: dict) -> str:
    if state.get("idle") and state.get("unmerged"):
        return (
            f"{state['unmerged']} is closed on branch {state['branch']} but not merged.\n"
            f"Finish REPLAN (prune, check, commit), then MERGE. "
            f"Next after that: {state.get('next_todo') or 'nothing todo'}."
        )
    if state.get("idle"):
        if state.get("next_todo"):
            return (
                f"Nothing in progress. Next in the backlog: "
                f"{state['next_todo']} -- {state['next_title']}.\n"
                f"Say the word and I will start it at GRILL."
            )
        if state.get("blocked"):
            return (
                "Nothing in progress and every todo is blocked: "
                f"{', '.join(state['blocked'])}. Fix a `depends_on` or reopen what they wait for."
            )
        return "Nothing in progress and nothing todo. The backlog is empty."
    ft = state["feature"]
    phase = state["phase"]
    lines = [
        f"{ft['id']} -- {ft['title']}",
        f"  phase   {phase.upper()} -> next {NEXT_PHASE[phase]}",
        f"  branch  {state.get('branch') or '?'}"
        f"{'  (uncommitted changes present)' if state.get('dirty') else ''}",
        f"  plan    {state.get('plan') or '(none yet)'}",
    ]
    if state.get("next"):
        lines.append(f"  next    {state['next']}")
    lines.append(f"  read    python3 scripts/feature.py {ft['id']}  +  {state.get('plan') or ''}")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    checking = argv[:1] == ["--check"]
    state, problems = collect()
    if problems:
        for p in problems:
            print(f"::error::resume: {p}")
        print(
            "\nresume: the pointers disagree, so no brief is printed. Fix the "
            "contradiction above before continuing."
        )
        return 1
    if checking:
        print("resume-check: OK (`go` has exactly one unambiguous place to start)")
        return 0
    print(brief(state))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
