#!/usr/bin/env python3
"""Validate docs/features.json -- the machine-checked feature list.

Checks: schema shape, unique F-ids, status/tier/phase enums, and the hard
rules: a `done` feature must cite at least one test whose file exists, a
`dropped` feature must carry a reason in `notes`, an `in-progress` feature
carries its `phase` and `next` (and nothing else does), GREEN and REVIEW
cite a test, `depends_on` names real ids and has no cycle, and a feature with a surface (not
"none") may not leave GRILL without citing an existing mockup file under
docs/design/mockups/ -- except a `dropped` feature, which never needed one.
Test EXECUTION is the quality gate's job, not this script's. Run locally or in CI:

    python3 scripts/features_check.py
"""

from __future__ import annotations

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import backlog  # noqa: E402

REQUIRED = ("id", "title", "intent", "serves", "acceptance", "tests", "status", "tier", "surface")
STATUSES = {"todo", "in-progress", "done", "dropped"}
TIERS = {"chore", "feature"}
PHASES = {"grill", "red", "green", "review"}
ID_RE = re.compile(r"^F\d{3}$")
PATH = os.path.join("docs", "features.json")
PLANS = os.path.join("docs", "plans")


def check(plans: bool = True, data: dict | None = None) -> list[str]:
    """`plans=False` skips the orphan-plan check: `feature.py` sets `done` one
    step before `prune.py` deletes the plan, so that transition is legal.
    `data` checks an in-memory list instead of the file, so `feature.py` can
    validate an update before it writes it."""
    if data is None:
        try:
            with open(PATH, encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, json.JSONDecodeError) as exc:
            return [f"{PATH}: {exc}"]
    feats = data.get("features")
    if not isinstance(feats, list) or not feats:
        return [f"{PATH}: 'features' must be a non-empty list"]
    errors: list[str] = []
    seen: set[str] = set()
    for i, ft in enumerate(feats):
        where = f"features[{i}]"
        if not isinstance(ft, dict):
            errors.append(f"{where}: must be an object")
            continue
        missing = [k for k in REQUIRED if k not in ft]
        if missing:
            errors.append(f"{where}: missing {missing}")
            continue
        fid = ft["id"]
        where = f"{fid} ({where})"
        if not isinstance(fid, str) or not ID_RE.match(fid):
            errors.append(f"{where}: id must match F000-F999")
        elif fid in seen:
            errors.append(f"{where}: duplicate id")
        else:
            seen.add(fid)
        if ft["status"] not in STATUSES:
            errors.append(f"{where}: status must be one of {sorted(STATUSES)}")
        if ft["tier"] not in TIERS:
            errors.append(f"{where}: tier must be one of {sorted(TIERS)}")
        phase = ft.get("phase")
        if ft["status"] == "in-progress" and phase not in PHASES:
            errors.append(f"{where}: in-progress needs phase in {sorted(PHASES)}")
        elif ft["status"] != "in-progress" and ("phase" in ft or "next" in ft):
            errors.append(f"{where}: phase/next only belong on an in-progress feature")
        nxt = ft.get("next")
        owed = "next" in ft or ft["status"] == "in-progress"
        if owed and not (isinstance(nxt, str) and nxt.strip()):
            errors.append(f"{where}: next must be a non-empty string (the single next action)")
        for key in ("decisions", "depends_on"):
            vals = ft.get(key, [])
            if not (isinstance(vals, list) and all(isinstance(v, str) and v.strip() for v in vals)):
                errors.append(f"{where}: {key} must be a list of non-empty strings")
        surface = ft["surface"]
        if not isinstance(surface, str) or not surface.strip():
            errors.append(f"{where}: surface must be a non-empty string ('none' if not visual)")
        elif surface != "none" and ft["status"] not in ("todo", "dropped") and phase != "grill":
            # GRILL is where the mockup gets built, so it is owed from RED on.
            mockup = ft.get("mockup")
            if not isinstance(mockup, str) or not mockup.strip():
                errors.append(
                    f"{where}: surface feature past GRILL needs a 'mockup' path "
                    f"(docs/design/mockups/...) -- no mockup, no code"
                )
            elif os.path.isabs(mockup) or ".." in mockup.split(os.sep):
                errors.append(
                    f"{where}: mockup must be a repo-relative path with no '..' component: {mockup}"
                )
            elif not mockup.startswith("docs/design/mockups/") or not os.path.isfile(mockup):
                errors.append(f"{where}: mockup file missing: {mockup}")
        acceptance = ft["acceptance"]
        if not isinstance(acceptance, list) or not acceptance:
            errors.append(f"{where}: acceptance must be a non-empty list")
        else:
            for j, a in enumerate(acceptance):
                if not isinstance(a, str) or not a.strip():
                    errors.append(f"{where}: acceptance[{j}] must be a non-empty string")
        tests = ft["tests"]
        if not isinstance(tests, list):
            errors.append(f"{where}: tests must be a list")
            tests = []
        else:
            for j, t in enumerate(tests):
                if not isinstance(t, str) or not t.strip():
                    errors.append(f"{where}: tests[{j}] must be a non-empty string")
                    continue
                test_file = t.split("::", 1)[0]
                if not test_file:
                    errors.append(f"{where}: tests[{j}] has no file part before '::'")
                    continue
                if os.path.isabs(test_file) or ".." in test_file.split(os.sep):
                    errors.append(
                        f"{where}: tests[{j}] must be a repo-relative "
                        f"path with no '..' component: {test_file}"
                    )
                    continue
                if ft["status"] == "done" and not os.path.isfile(test_file):
                    errors.append(f"{where}: cited test file missing: {test_file}")
        if ft["status"] == "done" and not tests:
            errors.append(f"{where}: done with no mapped tests")
        if phase in ("green", "review") and not tests:
            errors.append(f"{where}: {phase} with no cited test -- RED comes first")
        if not isinstance(ft.get("reviews", 0), int):
            errors.append(f"{where}: reviews is a count that scripts/feature.py keeps")
        notes = ft.get("notes")
        if "notes" in ft and not isinstance(notes, str):
            errors.append(f"{where}: notes must be a string")
        if ft["status"] == "dropped" and not str(notes or "").strip():
            errors.append(f"{where}: dropped without a reason in notes")
    if not errors:
        errors += backlog.dep_errors(feats)
    if plans:
        errors += orphan_plans(feats)
    return errors


def orphan_plans(feats: list) -> list[str]:
    """A plan outlives its feature only if someone forgot to delete it."""
    closed = {ft["id"] for ft in feats if ft["status"] in ("done", "dropped")}
    out = []
    if not os.path.isdir(PLANS):
        return out
    for name in sorted(os.listdir(PLANS)):
        if not name.endswith(".md") or name == "README.md":
            continue
        stem = name[:-3]
        fid = next(
            (i for i in closed if stem == i or stem.lower().startswith(i.lower() + "-")), None
        )
        if fid:
            out.append(
                f"{PLANS}/{name}: {fid} is closed, so this plan should have been "
                f"deleted at merge. Anything in it that still changes a decision "
                f"belongs in features.json, a gotcha, or SECURITY.md first."
            )
    return out


def main() -> int:
    errors = check()
    if errors:
        print("features-check: FAIL")
        for e in errors:
            print(f"  - {e}")
        return 1
    with open(PATH, encoding="utf-8") as f:
        feats = json.load(f)["features"]
    done = sum(1 for ft in feats if ft["status"] == "done")
    print(f"features-check: OK ({done}/{len(feats)} done)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
