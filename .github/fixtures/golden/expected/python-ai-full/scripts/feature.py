#!/usr/bin/env python3
"""Read or update ONE entry of docs/features.json -- the loop's state.

    python3 scripts/feature.py F012                          # print the entry
    python3 scripts/feature.py F012 status=in-progress phase=grill
    python3 scripts/feature.py F012 phase=green next="make AC3 pass"
    python3 scripts/feature.py F012 tests+=tests/test_x.py::test_a
    python3 scripts/feature.py F012 notes+="deviation: kept sync I/O, plan said async"
    python3 scripts/feature.py F012 mockup=docs/design/mockups/F012-list.html

    python3 scripts/feature.py F012 decisions+="owner said no to offline mode"
    python3 scripts/feature.py F012 depends_on+=F003

Writable keys: status, phase, next, mockup, tests / decisions / depends_on
(+= appends one), notes (+= appends one line). `status`, `tier`, `phase` values are the enums
features_check.py validates. Leaving in-progress drops phase and next.
The write is validated before it lands; an invalid update changes nothing.
"""

from __future__ import annotations

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import features_check  # noqa: E402

PATH = os.path.join("docs", "features.json")
SET_KEYS = {"status", "phase", "next", "mockup", "tier", "surface"}
APPEND_KEYS = {"tests", "notes", "decisions", "depends_on"}


def load() -> dict:
    with open(PATH, encoding="utf-8") as f:
        return json.load(f)


def save(data: dict) -> None:
    tmp = PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, PATH)  # the live file is never half-written


def apply(ft: dict, updates: list[str]) -> list[str]:
    errors: list[str] = []
    for upd in updates:
        if "+=" in upd:
            key, _, value = upd.partition("+=")
            if key not in APPEND_KEYS:
                errors.append(f"{key!r} does not take +=; use it with {sorted(APPEND_KEYS)}")
                continue
            if key != "notes":
                ft.setdefault(key, [])
                if value not in ft[key]:
                    ft[key].append(value)
            else:
                ft["notes"] = (ft.get("notes", "").rstrip("\n") + "\n" + value).strip("\n")
            continue
        key, sep, value = upd.partition("=")
        if not sep or key not in SET_KEYS:
            errors.append(f"cannot set {key!r}; writable keys: {sorted(SET_KEYS | APPEND_KEYS)}")
            continue
        if value == "":
            ft.pop(key, None)
        else:
            ft[key] = value
    if ft.get("status") != "in-progress":
        ft.pop("phase", None)
        ft.pop("next", None)
    return errors


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__.strip().splitlines()[0])
        print("usage: feature.py <id> [key=value | key+=value ...]")
        return 1
    fid, updates = argv[0], argv[1:]
    try:
        data = load()
    except (OSError, json.JSONDecodeError) as exc:
        print(f"feature: cannot read {PATH}: {exc}")
        return 1
    ft = next((f for f in data.get("features", []) if f.get("id") == fid), None)
    if ft is None:
        ids = ", ".join(f.get("id", "?") for f in data.get("features", []))
        print(f"feature: no entry {fid!r}. Known ids: {ids}")
        return 1
    if not updates:
        print(json.dumps(ft, indent=2, ensure_ascii=False))
        return 0
    errors = apply(ft, updates) or features_check.check(plans=False, data=data)
    if not errors:
        save(data)
    if errors:
        print(f"feature: {fid} unchanged")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"feature: {fid} " + " ".join(updates))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
