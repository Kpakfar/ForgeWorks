#!/usr/bin/env python3
"""ForgeWorks deterministic renderer.

Turns an interview answers file into a generated project tree: core template +
exactly one language profile, every placeholder substituted, every conditional
rule applied. Same answers in, same bytes out -- generation is this script, not
agent judgment (the agent's job ends at writing the answers file).

Usage:
    python3 render.py --answers <answers.json> --core <core-dir> \
        --profile <profile-dir> --out <target-dir>

Stdlib only. Plain string substitution (no template engine), per the repo
conventions. Fails closed: invalid answers, an unknown placeholder, a missing
insertion anchor, or a leftover {{...}} in the output all abort with a clear
message and a non-zero exit.

The rules implemented here are documented (as a summary table) in
init-project/SKILL.md Phase 4; the conditional block texts live in
templates/conditional/ next to the core templates.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys

from render_schema import (
    PLACEHOLDER_RE, PROFILE_NOTES, PROFILE_SCALARS, SECURITY_KEYS,
    RenderError, load_profile, validate_answers,
)

# Stamped into .claude/.template-version when the bootstrap install did not
# already write one. Bump on release (see the repo AGENTS.md <release-process>).
TEMPLATE_VERSION = "v2.5.0"

AI_FENCE_START_RE = re.compile(r"^\s*<!-- AI-[A-Z]+-START -->\s*$")
AI_FENCE_END_RE = re.compile(r"^\s*<!-- AI-[A-Z]+-END -->\s*$")

# CC fences: same mechanics as AI fences, but keyed on "claude-code in the
# agents roster" rather than ai_features -- used where a doc lists parts of
# the .claude/ tree that only ship for a Claude Code roster (e.g. structure.txt).
CC_FENCE_START_RE = re.compile(r"^\s*<!-- CC-[A-Z]+-START -->\s*$")
CC_FENCE_END_RE = re.compile(r"^\s*<!-- CC-[A-Z]+-END -->\s*$")

# Free-text (interview prose) placeholders may land verbatim only in Markdown
# and plain-text files, or escaped into JSON/TOML. Anywhere else is an error --
# hostile answer text must never be able to break a script or workflow.
FREE_TEXT_PLACEHOLDERS = {
    "PROJECT_NAME", "PROJECT_GOAL", "PRIMARY_USER", "CORE_PROBLEM",
    "CORE_JOURNEY", "SUCCESS_MEASURE", "SUCCESS_METRICS",
    "RISKIEST_ASSUMPTION", "REQ_AC_LIST", "NON_GOALS", "OTHER_USERS",
    "CONSTRAINT_TIME", "CONSTRAINT_COST", "CONSTRAINT_DATA",
    "FIRST_MILESTONE", "DEPLOYMENT_TARGET", "SCALE_EXPECTATIONS",
    "INTEGRATIONS", "IN_SCOPE_LIST", "PAIN_POINT", "PRODUCT_CATEGORY",
    "CURRENT_ALTERNATIVE", "KEY_BENEFIT", "KEY_DIFFERENTIATOR",
    "BACKEND_FRAMEWORK", "VECTOR_DB", "LLM_PROVIDER", "EMBEDDINGS_MODEL",
    "DATABASE", "POSITIVE_REFERENCE_TEXT", "NEGATIVE_REFERENCE_TEXT",
}

NO_BROWSER_STEP = "# no browser needed for this project's e2e suite"

# Offload roles each agent can cover in docs/agents.json. The file is a
# RUNTIME config: users edit it (or run /select-agents) when the roster
# changes mid-project; these are only the rendered starting values.
AGENT_ROLES = {
    "claude-code": ["orchestrator", "utility", "second_opinion", "heavy_batch"],
    "codex": ["second_opinion", "heavy_batch"],
    "antigravity": ["second_opinion", "heavy_batch"],
    "cursor": ["second_opinion"],
    "other": [],
}


def claude_selected(ans: dict) -> bool:
    return any(a["name"] == "claude-code" for a in ans["agents"])


# ------------------------------------------------------------------- mapping

def _conditional(cond_dir: str, name: str) -> str:
    path = os.path.join(cond_dir, name)
    if not os.path.isfile(path):
        raise RenderError(f"conditional block text missing: {path}")
    with open(path, encoding="utf-8") as f:
        return f.read()


def build_mapping(ans: dict, prof: dict, cond_dir: str) -> dict[str, str]:
    """Placeholder name -> substituted value (before per-format escaping)."""
    p, s = ans["project"], ans["stack"]
    ai_on = bool(s["ai_features"])
    mem0 = ans["opt_ins"]["mem0"] == "yes"
    codex = ans["opt_ins"]["codex_reviewer"] == "yes"

    pos, neg = p["positive_reference"], p["negative_reference"]
    positive_text = (
        f"Pattern-match every file you write or modify to {pos['ref']}. "
        f"Reference material: {pos['location']}."
        if pos else
        "<!-- No positive reference yet. Add one to this block when you choose one. -->"
    )
    negative_text = (
        f"Explicitly avoid the shape of {neg['ref']}. "
        f"Anti-pattern material: {neg['location']}."
        if neg else ""
    )
    if s["has_frontend"] != "no" and prof["e2e_browser_install"]:
        browser_step = ("- name: Install browsers\n"
                        f"  run: {prof['e2e_browser_install']}")
    else:
        browser_step = NO_BROWSER_STEP

    matrix_parts = []
    for agent in ans["agents"]:
        snippet = _conditional(cond_dir,
                               os.path.join("agents", agent["name"] + ".md")).rstrip("\n")
        if agent["status"] == "planned":
            snippet += ("\n\n> Status: **planned** -- selected in the interview but not "
                        "detected as installed. Run `/select-agents` (or edit "
                        "`docs/agents.json`) once it is available.")
        matrix_parts.append(snippet)
    if not claude_selected(ans):
        matrix_parts.append(_conditional(
            cond_dir, os.path.join("agents", "no-claude-note.md")).rstrip("\n"))

    mapping = {
        "PROJECT_NAME": p["name"], "PROJECT_GOAL": p["goal"],
        "PROJECT_SLUG": p["slug"], "PRIMARY_USER": p["primary_user"],
        "CORE_PROBLEM": p["core_problem"], "CORE_JOURNEY": p["core_journey"],
        "SUCCESS_MEASURE": p["success_measure"],
        "SUCCESS_METRICS": p["success_metrics"],
        "RISKIEST_ASSUMPTION": p["riskiest_assumption"],
        "REQ_AC_LIST": p["req_ac_list"], "NON_GOALS": p["non_goals"],
        "OTHER_USERS": p["other_users"],
        "CONSTRAINT_TIME": p["constraint_time"],
        "CONSTRAINT_COST": p["constraint_cost"],
        "CONSTRAINT_DATA": p["constraint_data"],
        "FIRST_MILESTONE": p["first_milestone"],
        "DEPLOYMENT_TARGET": p["deployment_target"],
        "SCALE_EXPECTATIONS": p["scale_expectations"],
        "INTEGRATIONS": p["integrations"], "IN_SCOPE_LIST": p["in_scope_list"],
        "PAIN_POINT": p["pain_point"],
        "PRODUCT_CATEGORY": p["product_category"],
        "CURRENT_ALTERNATIVE": p["current_alternative"],
        "KEY_BENEFIT": p["key_benefit"],
        "KEY_DIFFERENTIATOR": p["key_differentiator"],
        "POSITIVE_REFERENCE_TEXT": positive_text,
        "NEGATIVE_REFERENCE_TEXT": negative_text,
        "LANGUAGE": prof["display_name"], "HAS_FRONTEND": s["has_frontend"],
        "BACKEND_FRAMEWORK": s["backend_framework"],
        "AI_FEATURES": ", ".join(s["ai_features"]) if ai_on else "none",
        "VECTOR_DB": s["vector_db"], "LLM_PROVIDER": s["llm_provider"],
        "EMBEDDINGS_MODEL": s["embeddings_model"], "DATABASE": s["database"],
        "USES_DEVCONTAINER": s["uses_devcontainer"],
        "READS_UNTRUSTED": ans["security"]["reads_untrusted"],
        "HOLDS_PRIVATE_DATA": ans["security"]["holds_private_data"],
        "ACTS_OUTWARD": ans["security"]["acts_outward"],
        "DATE": ans["date"],
        "AI_DISCIPLINE_BLOCK": (_conditional(cond_dir, "ai-discipline.md").rstrip("\n")
                                if ai_on else ""),
        "AGENT_MATRIX": "\n\n".join(matrix_parts),
        "MEMORY_DOC_LINE": (_conditional(cond_dir, "memory-doc-line.md").rstrip("\n") + "\n"
                            if mem0 else ""),
        "CODEX_REVIEW_STEP": (_conditional(cond_dir, "codex-review-step.md").rstrip("\n")
                              if codex else ""),
        "CODEX_ROSTER_NOTE": (" " + _conditional(cond_dir, "codex-roster-note.md").strip()
                              if codex else ""),
        "E2E_BROWSER_INSTALL_STEP": browser_step,
    }
    for key in PROFILE_SCALARS:
        if key != "display_name":
            mapping[key.upper()] = prof[key]
    mapping["CI_SETUP_STEPS"] = "\n".join(prof["ci_setup_steps"])
    mapping["LANGUAGE_PRECOMMIT_HOOKS"] = "\n".join(prof["precommit_hooks"])
    mapping["LIBRARY_DOCS_URLS"] = "\n".join(prof["library_docs_urls"])
    for key, placeholder in PROFILE_NOTES.items():
        mapping[placeholder] = "\n".join(prof["notes"][key])
    # E2E_BROWSER_INSTALL is a profile scalar but never a placeholder on its
    # own; only the derived step above lands in files.
    mapping.pop("E2E_BROWSER_INSTALL", None)
    return mapping


# ------------------------------------------------------------- text rewriting

def toml_escape(value: str) -> str:
    out = value.replace("\\", "\\\\").replace('"', '\\"')
    out = out.replace("\n", "\\n").replace("\t", "\\t")
    return "".join(c if ord(c) >= 32 else f"\\u{ord(c):04X}" for c in out)


def json_escape(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)[1:-1]


def file_format(relpath: str) -> str:
    name = os.path.basename(relpath)
    if name.endswith(".json"):
        return "json"
    if name.endswith(".toml"):
        return "toml"
    if name.endswith((".md", ".markdown", ".txt")):
        return "text"
    return "other"


def substitute(text: str, relpath: str, mapping: dict[str, str]) -> str:
    fmt = file_format(relpath)

    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        if key not in mapping:
            raise RenderError(f"{relpath}: unknown placeholder {{{{{key}}}}} -- "
                              "add it to the mapping in render.py")
        value = mapping[key]
        if fmt == "json":
            return json_escape(value)
        if fmt == "toml":
            return toml_escape(value)
        if fmt == "other" and key in FREE_TEXT_PLACEHOLDERS:
            raise RenderError(f"{relpath}: free-text placeholder {{{{{key}}}}} in a "
                              "structured file; refusing to substitute unescaped")
        if "\n" in value:  # re-indent so multi-line values keep the file valid
            line_start = text.rfind("\n", 0, match.start()) + 1
            prefix = text[line_start:match.start()]
            if not prefix.strip():
                value = value.replace("\n", "\n" + prefix)
        return value

    return PLACEHOLDER_RE.sub(repl, text)


def apply_fences(text: str, keep_content: bool, start_re: re.Pattern[str],
                 end_re: re.Pattern[str]) -> str:
    """Generic fence rule (shared by the AI and CC fence families): keep_content
    -> drop only the marker lines; not keep_content -> drop the whole fenced
    block (collapsing a doubled blank line at the seam)."""
    out: list[str] = []
    lines = text.splitlines(keepends=True)
    i = 0
    while i < len(lines):
        if keep_content and (start_re.match(lines[i]) or end_re.match(lines[i])):
            i += 1
            continue
        if not keep_content and start_re.match(lines[i]):
            while i < len(lines) and not end_re.match(lines[i]):
                i += 1
            i += 1  # the END marker line
            if (out and not out[-1].strip()
                    and i < len(lines) and not lines[i].strip()):
                i += 1  # collapse blank-blank seam left by the deletion
            continue
        out.append(lines[i])
        i += 1
    return "".join(out)


def insert_after(text: str, anchor: str, block: str, relpath: str) -> str:
    if text.count(anchor) != 1:
        raise RenderError(f"{relpath}: expected exactly one insertion anchor "
                          f"{anchor!r}; template drifted from render.py")
    return text.replace(anchor, anchor + block, 1)


def apply_insertions(text: str, relpath: str, ans: dict, cond_dir: str) -> str:
    """Conditional content that is inserted rather than substituted."""
    sec = ans["security"]
    trifecta = (bool(ans["stack"]["ai_features"])
                and all(sec[k] == "yes" for k in SECURITY_KEYS))
    if relpath == "AGENTS.md" and ans["opt_ins"]["mem0"] == "yes":
        block = _conditional(cond_dir, "memory-block.md").rstrip("\n")
        text = insert_after(text, "<!-- /FW-BLOCK: library-docs -->\n",
                            "\n" + block + "\n", relpath)
    if relpath == "docs/gotchas.md" and ans["opt_ins"]["seed_gotchas"] == "yes":
        seed = _conditional(cond_dir, "gotchas-seed.md").rstrip("\n")
        idx = text.find("\n---\n\n## Generic lessons")
        if idx < 0:
            raise RenderError(f"{relpath}: gotchas-seed anchor not found")
        text = text[:idx] + "\n" + seed + "\n" + text[idx:]
    if relpath == "docs/SECURITY.md":
        profile_line = (
            "Security profile (from the setup interview, B8): reads untrusted "
            f"content: **{sec['reads_untrusted']}**; holds private data: "
            f"**{sec['holds_private_data']}**; acts on the outside world: "
            f"**{sec['acts_outward']}**."
        )
        if trifecta:
            profile_line += (
                "\n\n**Lethal trifecta: PRESENT.** All three are true for this "
                "project. Break one leg -- split the agent, drop a capability, "
                "or gate the action behind a human -- and record the break "
                "under *How this project breaks the trifecta* below."
            )
        text = insert_after(
            text, 'Review each row "through the lens of an attacker."\n',
            "\n" + profile_line + "\n", relpath)
    if relpath == "docs/requirements.md" and trifecta:
        note = ("**Lethal trifecta: PRESENT.** All three answers above are yes "
                "for a single LLM agent. Break one leg -- split the agent, drop "
                "a capability, or gate the action behind a human -- and record "
                "the break here and in `docs/SECURITY.md`.")
        text = insert_after(
            text, "Full threat model and defenses: `docs/SECURITY.md`.\n",
            "\n" + note + "\n", relpath)
    return text


# ------------------------------------------------------------------ rendering

def skip_file(relpath: str, source: str, ans: dict) -> bool:
    parts = relpath.split(os.sep)
    if source == "profile" and relpath == "profile.json":
        return True  # renderer input, never part of a generated project
    if relpath == os.path.join(".claude", "hooks", "slice-audit.sh"):
        return False  # agent-neutral: CI invokes it as a plain script
                      # (`bash .claude/hooks/slice-audit.sh`) regardless of roster
    if (parts[0] == ".claude" and not claude_selected(ans)):
        return True  # Claude Code not in the roster: no agents/hooks/skills/settings
    if parts[0] == ".devcontainer" and ans["stack"]["uses_devcontainer"] == "no":
        return True
    if parts[:2] == ["docs", "explanations"] and ans["opt_ins"]["explanations"] == "no":
        return True
    return relpath == os.path.join("docs", "memory.md") and ans["opt_ins"]["mem0"] == "no"


def iter_files(root: str) -> list[str]:
    out: list[str] = []
    for dirpath, dirnames, names in os.walk(root):
        dirnames.sort()
        rel = os.path.relpath(dirpath, root)
        out += [os.path.normpath(os.path.join(rel, n)) for n in sorted(names)]
    return out


def render_file(src: str, dst: str, relpath: str, ans: dict,
                mapping: dict[str, str], cond_dir: str) -> None:
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    with open(src, "rb") as f:
        raw = f.read()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        with open(dst, "wb") as f:
            f.write(raw)  # binary: copy verbatim
        shutil.copymode(src, dst)
        return
    text = apply_fences(text, keep_content=bool(ans["stack"]["ai_features"]),
                        start_re=AI_FENCE_START_RE, end_re=AI_FENCE_END_RE)
    text = apply_fences(text, keep_content=claude_selected(ans),
                        start_re=CC_FENCE_START_RE, end_re=CC_FENCE_END_RE)
    text = substitute(text, relpath, mapping)
    text = apply_insertions(text, relpath, ans, cond_dir)
    with open(dst, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    shutil.copymode(src, dst)


def post_steps(out_dir: str, ans: dict) -> None:
    # CLAUDE.md -> AGENTS.md pointer only makes sense for a Claude Code roster.
    claude_md = os.path.join(out_dir, "CLAUDE.md")
    if claude_selected(ans):
        if os.path.lexists(claude_md):
            os.remove(claude_md)
        try:
            os.symlink("AGENTS.md", claude_md)
        except (OSError, NotImplementedError):
            with open(claude_md, "w", encoding="utf-8") as f:
                f.write("# See @AGENTS.md\n")
    # Shell runners and hooks must be executable.
    for sub in (os.path.join(".claude", "hooks"), "scripts"):
        folder = os.path.join(out_dir, sub)
        if os.path.isdir(folder):
            for name in sorted(os.listdir(folder)):
                if name.endswith(".sh"):
                    os.chmod(os.path.join(folder, name), 0o755)
    # Machine-readable agent roster -- the runtime offload config.
    agents_json = os.path.join(out_dir, "docs", "agents.json")
    os.makedirs(os.path.dirname(agents_json), exist_ok=True)
    payload = {"schema": 1,
               "agents": [{"name": a["name"], "status": a["status"],
                           "roles": AGENT_ROLES[a["name"]]}
                          for a in ans["agents"]]}
    with open(agents_json, "w", encoding="utf-8", newline="") as f:
        json.dump(payload, f, indent=2, sort_keys=True)
        f.write("\n")
    # Template version stamp is ALWAYS written (upgrade-project depends on it),
    # even when the roster has no claude-code (bootstrap normally writes it first).
    stamp = os.path.join(out_dir, ".claude", ".template-version")
    if not os.path.exists(stamp):
        os.makedirs(os.path.dirname(stamp), exist_ok=True)
        with open(stamp, "w", encoding="utf-8") as f:
            f.write(TEMPLATE_VERSION + "\n")


def leftover_scan(out_dir: str) -> list[str]:
    skip_dirs = {".git", "node_modules", ".venv", "skills"}
    found: list[str] = []
    for dirpath, dirnames, names in os.walk(out_dir):
        dirnames[:] = sorted(d for d in dirnames if d not in skip_dirs)
        for name in sorted(names):
            path = os.path.join(dirpath, name)
            if os.path.islink(path):
                continue
            try:
                with open(path, encoding="utf-8") as f:
                    content = f.read()
            except (UnicodeDecodeError, OSError):
                continue
            found += [f"{os.path.relpath(path, out_dir)}: {{{{{m}}}}}"
                      for m in PLACEHOLDER_RE.findall(content)]
    return found


def render(answers_path: str, core_dir: str, profile_dir: str, out_dir: str) -> int:
    with open(answers_path, encoding="utf-8") as f:
        try:
            ans = json.load(f)
        except json.JSONDecodeError as exc:
            raise RenderError(f"answers file is not valid JSON: {exc}") from exc
    ans = validate_answers(ans)
    prof = load_profile(profile_dir)
    lang_dir = os.path.basename(os.path.normpath(profile_dir))
    if lang_dir != ans["stack"]["language"]:
        raise RenderError(f"--profile points at {lang_dir!r} but answers say "
                          f"stack.language = {ans['stack']['language']!r}")
    cond_dir = os.path.normpath(os.path.join(core_dir, "..", "conditional"))
    mapping = build_mapping(ans, prof, cond_dir)

    written = 0
    for source, root in (("core", core_dir), ("profile", profile_dir)):
        for relpath in iter_files(root):
            if skip_file(relpath, source, ans):
                continue
            # Profile manifests ship with an .example suffix so the template
            # repo's own tooling ignores them (e.g. pyproject.toml.example).
            # Core files never do -- .env.example is genuinely named that.
            target_rel = (relpath[:-len(".example")]
                          if source == "profile" and relpath.endswith(".example")
                          else relpath)
            render_file(os.path.join(root, relpath),
                        os.path.join(out_dir, target_rel),
                        target_rel, ans, mapping, cond_dir)
            written += 1
    post_steps(out_dir, ans)

    leftovers = leftover_scan(out_dir)
    if leftovers:
        raise RenderError("unresolved placeholders survived the render "
                          "(fail closed):\n  - " + "\n  - ".join(leftovers))
    roster = ",".join(f"{a['name']}({a['status'][0]})" for a in ans["agents"])
    print(f"rendered {written} files -> {out_dir} "
          f"[{ans['stack']['language']}; ai={'on' if ans['stack']['ai_features'] else 'off'}; "
          f"devcontainer={ans['stack']['uses_devcontainer']}; "
          f"mem0={ans['opt_ins']['mem0']}; codex={ans['opt_ins']['codex_reviewer']}; "
          f"agents={roster}]")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--answers", required=True, help="answers JSON file")
    parser.add_argument("--core", required=True, help="templates/core directory")
    parser.add_argument("--profile", required=True,
                        help="templates/profiles/<language> directory")
    parser.add_argument("--out", required=True, help="target project directory")
    args = parser.parse_args(argv)
    for label, path in (("--answers", args.answers), ("--core", args.core),
                        ("--profile", args.profile)):
        if not os.path.exists(path):
            print(f"render.py: {label} path does not exist: {path}", file=sys.stderr)
            return 2
    try:
        return render(args.answers, args.core, args.profile, args.out)
    except RenderError as exc:
        print(f"render.py: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
