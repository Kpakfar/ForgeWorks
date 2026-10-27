#!/usr/bin/env python3
"""Regenerate docs/BACKLOG.md, the human-readable view of docs/features.json.

    python3 scripts/backlog.py

`scripts/prune.py` runs this at every merge, so the file is rarely written by
hand. To read ONE feature, use `scripts/feature.py <id>` -- a working session
never reads features.json whole. This file also owns the dependency graph:
`depends_on` edges, which features are ready, and the cycle check.
"""

from __future__ import annotations

import json
import os
import sys

SRC = os.path.join("docs", "features.json")
DST = os.path.join("docs", "BACKLOG.md")
ICONS = {"done": "[x]", "in-progress": "[~]", "todo": "[ ]", "dropped": "[-]"}


def blocked_by(ft: dict, feats: list) -> list[str]:
    """The ids in `depends_on` that are not done yet. Empty means ready."""
    done = {f["id"] for f in feats if f["status"] == "done"}
    return [d for d in ft.get("depends_on", []) if d not in done]


def dep_errors(feats: list) -> list[str]:
    """Every edge names another existing feature, and the edges form no cycle."""
    deps = {ft["id"]: ft.get("depends_on", []) for ft in feats}
    out = [
        f"{fid}: depends_on names unknown or own id {d!r}"
        for fid, ds in deps.items()
        for d in ds
        if d not in deps or d == fid
    ]
    state: dict[str, int] = {}

    def visit(fid: str) -> bool:
        if state.get(fid) == 1:
            return True
        if state.get(fid) == 2:
            return False
        state[fid] = 1
        cyclic = any(visit(d) for d in deps.get(fid, []) if d in deps)
        state[fid] = 2
        return cyclic

    return out or [f"{fid}: depends_on forms a cycle" for fid in deps if visit(fid)][:1]


def load() -> list | None:
    try:
        with open(SRC, encoding="utf-8") as f:
            return json.load(f)["features"]
    except (OSError, KeyError, json.JSONDecodeError) as exc:
        print(f"backlog: cannot read {SRC}: {exc}")
        return None


def regenerate(feats: list) -> int:
    lines = [
        "# Backlog",
        "",
        "Generated from `docs/features.json` by `scripts/backlog.py` -- do not edit by hand.",
        "Order is priority order. `[x]` done, `[~]` in progress, `[ ]` todo, `[-]` dropped.",
        "",
    ]
    done = 0
    for ft in feats:
        fid = ft.get("id")
        if not fid:
            print(f"backlog: entry missing id: {ft!r}")
            return 1
        icon = ICONS.get(ft.get("status", "todo"), "[?]")
        if ft.get("status") == "done":
            done += 1
        waits = blocked_by(ft, feats) if ft.get("status") == "todo" else []
        blocked = f" (waits for {', '.join(waits)})" if waits else ""
        lines.append(f"- {icon} **{fid}** {ft.get('title', '')}{blocked}")
    lines += ["", f"{done}/{len(feats)} done.", ""]
    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"backlog: wrote {DST} ({done}/{len(feats)} done)")
    return 0


def main(argv: list[str]) -> int:
    if argv:
        print(f"backlog: unknown argument {argv[0]!r}; this script takes none")
        return 1
    feats = load()
    return 1 if feats is None else regenerate(feats)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
