#!/usr/bin/env python3
"""skills doctor -- the instruction stack a session actually starts with.

The repo-side checkpoint budget (CI `checkpoint-budget`) sees repo files only.
The session also loads global CLAUDE.md files, the memory index, every enabled
plugin's skill listing and SessionStart hooks. This script prints that real
inventory and fails on the two things a field project paid for:
  FAIL  one skill name installed from more than one source (routing races; the
        generic copy wins and generic output ships) -- the one-copy rule.
  FAIL  an enabled plugin that injects a SessionStart hook into EVERY session
        AND ships a process skill (tdd / grilling / debugging / review): it
        preempts the project's own loop and breaks the checkpoint.
  WARN  any other plugin with a SessionStart hook -- environment setup is a
        legitimate use; check it does not steer the process.
  WARN  several skills from one process family (tdd / grilling / debugging /
        review) -- legal, but AGENTS.md names one owner per family.
Exit 1 on any FAIL. Read-only; it never edits settings. Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

FAMILIES = {
    "tdd": {"tdd", "test-driven-development"},
    "grilling": {"grill-me", "grill-with-docs", "brainstorming"},
    "debugging": {"diagnose", "diagnosing-bugs", "systematic-debugging"},
    "review": {"code-review", "requesting-code-review", "receiving-code-review"},
}
IMPORT = re.compile(r"^@(\S+)", re.M)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def skills_under(root: Path) -> list[tuple[str, Path]]:
    """(name, realpath) for every */SKILL.md under root; name = parent dir."""
    if not root.is_dir():
        return []
    return sorted((p.parent.name, p.parent.resolve()) for p in root.rglob("SKILL.md"))


def enabled_plugins(home: Path) -> list[tuple[str, Path]]:
    installed = load_json(home / ".claude" / "plugins" / "installed_plugins.json")
    flags = load_json(home / ".claude" / "settings.json").get("enabledPlugins", {})
    out = []
    for key, entries in installed.get("plugins", {}).items():
        if flags.get(key, True) is False or not entries:
            continue
        out.append((key, Path(entries[0].get("installPath", ""))))
    return out


def size_with_imports(path: Path) -> int:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return 0
    total = len(text)
    for ref in IMPORT.findall(text):  # one level, the way the harness resolves them
        p = Path(os.path.expanduser(ref))
        p = p if p.is_absolute() else path.parent / p
        total += len(p.read_text(encoding="utf-8")) if p.is_file() else 0
    return total


def claude_md_chain(root: Path, home: Path) -> list[tuple[str, int, bool]]:
    """(label, size, counted) -- the project's own AGENTS.md (reached via the
    CLAUDE.md symlink) is already in the repo-side checkpoint, so counted=False."""
    seen: list[tuple[str, int, bool]] = []
    agents = (root / "AGENTS.md").resolve()
    candidates = [home / ".claude" / "CLAUDE.md"]
    for d in [root, *root.parents]:
        candidates += [d / "CLAUDE.md", d / "CLAUDE.local.md"]
    for c in candidates:
        if c.is_file():
            seen.append(
                (str(c).replace(str(home), "~"), size_with_imports(c), c.resolve() != agents)
            )
    return seen


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=".", help="project root (default: cwd)")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    home = Path(os.environ.get("HOME", "~")).expanduser().resolve()
    fails, warns = [], []

    # 1. skill inventory -- every source, deduped by real path (a symlink is not a copy)
    sources = {
        "project .claude/skills": root / ".claude" / "skills",
        "personal ~/.claude/skills": home / ".claude" / "skills",
        "standalone ~/.agents/skills": home / ".agents" / "skills",
    }
    plugins = enabled_plugins(home)
    for key, path in plugins:
        sources[f"plugin {key}"] = path / "skills"
    by_name: dict[str, dict[Path, str]] = {}
    for label, src in sources.items():
        for name, real in skills_under(src):
            by_name.setdefault(name, {}).setdefault(real, label)
    print("== skills (one copy per name is the rule) ==")
    print(
        f"  {len(by_name)} skill names from {len(sources)} sources ({len(plugins)} enabled plugins)"
    )
    for name, copies in sorted(by_name.items()):
        if len(copies) > 1:
            fails.append(
                f"`{name}` installed {len(copies)}x: " + "; ".join(sorted(copies.values()))
            )
    for family, names in FAMILIES.items():
        present = sorted(n for n in names if n in by_name)
        if len(present) > 1:
            warns.append(f"{family} family has {len(present)} skills: {', '.join(present)}")

    # 2. always-on SessionStart injection
    print("== session-start hooks ==")
    for key, path in plugins:
        hooks = load_json(path / "hooks" / "hooks.json").get("hooks", {})
        if "SessionStart" not in hooks:
            continue
        process = sorted(
            n
            for n, _ in skills_under(path / "skills")
            if any(n in names for names in FAMILIES.values())
        )
        if process:
            fails.append(
                f"plugin {key} injects a SessionStart hook into every session "
                f"and ships process skills ({', '.join(process)})"
            )
        else:
            warns.append(
                f"plugin {key} injects a SessionStart hook into every session "
                "(no process skills; check it only sets up the environment)"
            )
    for label, settings in (
        ("user", home / ".claude" / "settings.json"),
        ("project", root / ".claude" / "settings.json"),
    ):
        n = len(load_json(settings).get("hooks", {}).get("SessionStart", []))
        if n:
            print(f"  {label} settings: {n} SessionStart hook group(s) (owner-configured)")

    # 3. the real session-start inventory -- the CI budget is the floor, not the total
    print("== session-start inventory (the checkpoint-budget job sees only the repo side) ==")
    chain = claude_md_chain(root, home)
    for path, size, counted in chain:
        print(f"  {size:>7} chars  {path}{'' if counted else '  (= AGENTS.md, repo side)'}")
    key = str(root).replace("/", "-")
    mem = home / ".claude" / "projects" / key / "memory" / "MEMORY.md"
    mem_size = len(mem.read_text(encoding="utf-8")) if mem.is_file() else 0
    print(f"  {mem_size:>7} chars  memory index ({'present' if mem_size else 'none'})")
    iteration = root / ".claude" / "skills" / "iteration" / "SKILL.md"
    repo_side = sum(
        len(p.read_text(encoding="utf-8")) for p in (root / "AGENTS.md", iteration) if p.is_file()
    )
    mcp = len(load_json(root / ".mcp.json").get("mcpServers", {})) + len(
        load_json(home / ".claude.json").get("mcpServers", {})
    )
    total = sum(s for _, s, counted in chain if counted) + mem_size
    print(f"  repo-side checkpoint (AGENTS.md + iteration skill): ~{repo_side // 4} tokens")
    print(
        f"  machine-side load on top: ~{total // 4} tokens of CLAUDE.md chain + memory, "
        f"plus {len(by_name)} skill descriptions and {mcp} MCP server(s) (size unknown)"
    )

    print("== findings ==")
    for w in warns:
        print(f"  WARN  {w}")
    for f in fails:
        print(f"  FAIL  {f}")
    if not fails and not warns:
        print("  none")
    if fails:
        print(
            "Fix: keep ONE source per skill name and disable the rest (Claude Code: "
            "`/plugin`, or `enabledPlugins` in ~/.claude/settings.json). Never a "
            "process plugin that runs on every SessionStart next to this harness."
        )
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
