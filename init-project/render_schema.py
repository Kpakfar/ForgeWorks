#!/usr/bin/env python3
"""Answers-file and profile.json schema for the ForgeWorks renderer.

Hand-rolled validation (stdlib only) shared by render.py: required keys,
enums for language/frontend/AI-feature choices, yes/no fields, slug/date
formats, and hostile-text guards (control characters, HTML comment markers,
placeholder-shaped text). Everything fails closed with a message that names
the offending field.
"""

from __future__ import annotations

import json
import os
import re

PLACEHOLDER_RE = re.compile(r"\{\{([A-Z0-9_]+)\}\}")
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
STRUCTURAL_TAG_RE = re.compile(
    r"</?(project|commands|etiquette|hard-rules|tiers|communication|context"
    r"|learning|roster|ai-discipline|memory)>",
    re.IGNORECASE,
)

LANGUAGES = ("python", "typescript", "go", "rust")
WEIGHTS = ("lite", "full")
FRONTEND_CHOICES = ("yes-spa", "yes-minimal", "no")
AI_FEATURE_CHOICES = ("rag", "agents", "evals", "streaming")
AGENT_CHOICES = ("claude-code", "codex", "antigravity", "cursor", "opencode",
                 "other")
AGENT_STATUSES = ("installed", "planned")

# Answers-file layout: section -> required keys. All free-text unless
# validate_answers() handles the key specially (enums, yes/no, references).
PROJECT_KEYS = (
    "name", "slug", "goal", "primary_user", "core_problem", "core_journey",
    "success_measure", "success_metrics", "riskiest_assumption", "req_ac_list",
    "non_goals", "other_users", "constraint_time", "constraint_cost",
    "constraint_data", "first_milestone", "deployment_target",
    "scale_expectations", "integrations", "in_scope_list", "pain_point",
    "product_category", "current_alternative", "key_benefit",
    "key_differentiator", "positive_reference", "negative_reference",
    "surfaces",
)
STACK_KEYS = (
    "language", "has_frontend", "backend_framework", "ai_features",
    "vector_db", "llm_provider", "embeddings_model", "database",
    "uses_devcontainer",
)
SECURITY_KEYS = ("reads_untrusted", "holds_private_data", "acts_outward")
OPT_IN_KEYS = ("explanations", "seed_gotchas", "mem0", "codex_reviewer")
FEATURE_KEYS = ("id", "title", "intent", "serves", "acceptance", "tests",
                "status", "tier", "surface")
FEATURE_OPTIONAL_KEYS = ("mockup", "depends_on")
FEATURE_STATUSES = ("todo", "in-progress", "done", "dropped")
FEATURE_TIERS = ("chore", "feature")
FEATURE_ID_RE = re.compile(r"^F\d{3}$")
DESIGN_KEYS = ("references", "tone", "anti_reference")
TOP_LEVEL_KEYS = ("schema", "date", "agents", "project", "stack", "security",
                  "opt_ins", "features", "design", "weight")
SCHEMA_VERSION = 1

PROFILE_SCALARS = (
    "display_name", "language_version", "package_manager", "manifest_file",
    "install_command", "add_dep_command", "qa_command", "fix_command",
    "e2e_command", "e2e_browser_install", "test_runner", "test_command",
    "lint_tool", "lint_command", "format_tool", "format_command", "type_tool",
    "type_command", "precommit_install_command", "test_path_regex",
    "source_suffixes",
)
PROFILE_LISTS = ("ci_setup_steps", "precommit_hooks", "library_docs_urls")
# notes key in profile.json -> placeholder name (singular/plural is irregular).
PROFILE_NOTES = {
    "type_annotations": "TYPE_ANNOTATION_NOTES",
    "imports": "IMPORT_NOTES",
    "async": "ASYNC_NOTES",
    "errors": "ERROR_NOTES",
    "config": "CONFIG_NOTES",
    "logging": "LOGGING_NOTES",
    "test_layout": "TEST_LAYOUT_NOTES",
    "precommit_hooks": "PRECOMMIT_HOOKS_NOTES",
}


class RenderError(Exception):
    """Fatal, user-facing renderer failure."""


# ---------------------------------------------------------------- validation

def _check_text(errors: list[str], where: str, value: object) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{where}: must be a non-empty string")
        return
    cleaned = value.replace("\r\n", "\n").replace("\r", "\n")
    if any(ord(c) < 32 and c not in "\n\t" for c in cleaned):
        errors.append(f"{where}: contains control characters")
    if "<!--" in cleaned or "-->" in cleaned:
        errors.append(f"{where}: must not contain HTML comment markers "
                      "(<!-- or -->) -- they would break generated files")
    if STRUCTURAL_TAG_RE.search(cleaned):
        errors.append(f"{where}: must not contain AGENTS.md structural tags")
    if PLACEHOLDER_RE.search(cleaned):
        errors.append(f"{where}: contains text shaped like a template "
                      "placeholder ({{UPPER_SNAKE}}); not allowed in answers")


def _check_yes_no(errors: list[str], where: str, value: object) -> None:
    if value not in ("yes", "no"):
        errors.append(f'{where}: must be exactly "yes" or "no" (got {value!r})')


def _check_reference(errors: list[str], where: str, value: object) -> None:
    if value is None:
        return
    if not isinstance(value, dict) or set(value) != {"ref", "location"}:
        errors.append(f'{where}: must be null or {{"ref": ..., "location": ...}}')
        return
    _check_text(errors, f"{where}.ref", value["ref"])
    _check_text(errors, f"{where}.location", value["location"])


def _check_surfaces(errors: list[str], where: str, value: object) -> None:
    if not isinstance(value, list):
        errors.append(f"{where}: must be a list of non-empty strings ([] allowed)")
        return
    for i, item in enumerate(value):
        _check_text(errors, f"{where}[{i}]", item)


def _check_features(errors: list[str], value: object) -> None:
    if not isinstance(value, list) or not value:
        errors.append("features: must be a non-empty list of feature objects")
        return
    seen: set[str] = set()
    for i, ft in enumerate(value):
        where = f"features[{i}]"
        if not isinstance(ft, dict):
            errors.append(f"{where}: must be an object")
            continue
        extra = set(ft) - set(FEATURE_KEYS) - set(FEATURE_OPTIONAL_KEYS) - {"notes"}
        if extra:
            errors.append(f"{where}: unknown keys {sorted(extra)}")
        for key in FEATURE_KEYS:
            if key not in ft:
                errors.append(f"{where}.{key}: missing")
        if "id" in ft:
            fid = ft["id"]
            if not isinstance(fid, str) or not FEATURE_ID_RE.match(fid):
                errors.append(f"{where}.id: must match F000-F999 (got {fid!r})")
            elif fid in seen:
                errors.append(f"{where}.id: duplicate {fid}")
            else:
                seen.add(fid)
        for key in ("title", "intent", "serves"):
            if key in ft:
                _check_text(errors, f"{where}.{key}", ft[key])
        if "status" in ft and ft["status"] not in FEATURE_STATUSES:
            errors.append(f"{where}.status: must be one of {FEATURE_STATUSES}")
        if "tier" in ft and ft["tier"] not in FEATURE_TIERS:
            errors.append(f"{where}.tier: must be one of {FEATURE_TIERS}")
        if "surface" in ft:
            _check_text(errors, f"{where}.surface", ft["surface"])
        if "mockup" in ft:
            _check_text(errors, f"{where}.mockup", ft["mockup"])
        deps = ft.get("depends_on", [])
        if not isinstance(deps, list) or any(not isinstance(d, str) or d not in seen or d == ft.get("id") for d in deps):
            errors.append(f"{where}.depends_on: must list ids of features that appear "
                          "earlier in the array (no unknown id, no cycle)")
        acc = ft.get("acceptance")
        if "acceptance" in ft and (not isinstance(acc, list) or not acc
                                   or any(not isinstance(a, str) or not a.strip()
                                          for a in acc)):
            errors.append(f"{where}.acceptance: must be a non-empty list of strings")
        tests = ft.get("tests")
        if "tests" in ft and (not isinstance(tests, list)
                              or any(not isinstance(t, str) for t in tests)):
            errors.append(f"{where}.tests: must be a list of strings ([] until mapped)")


def _check_design(errors: list[str], value: object, has_frontend: str) -> None:
    if has_frontend == "no":
        if value is not None:
            errors.append('design: must be null when stack.has_frontend is "no"')
        return
    if not isinstance(value, dict) or set(value) != set(DESIGN_KEYS):
        errors.append(f'design: must be an object with keys {DESIGN_KEYS} '
                      '(required because the project has a frontend)')
        return
    for key in DESIGN_KEYS:
        _check_text(errors, f"design.{key}", value[key])


def validate_answers(ans: object) -> dict:
    """Validate the answers file against the documented schema. Fail closed."""
    errors: list[str] = []
    if not isinstance(ans, dict):
        raise RenderError("answers file: top level must be a JSON object")
    if ans.get("schema") != SCHEMA_VERSION:
        errors.append(f"schema: must be exactly {SCHEMA_VERSION} "
                      f"(got {ans.get('schema')!r})")
    unknown_top = set(ans) - set(TOP_LEVEL_KEYS)
    if unknown_top:
        errors.append(f"unknown top-level key(s): {sorted(unknown_top)}")
    for section, keys in (("project", PROJECT_KEYS), ("stack", STACK_KEYS),
                          ("security", SECURITY_KEYS), ("opt_ins", OPT_IN_KEYS)):
        block = ans.get(section)
        if not isinstance(block, dict):
            errors.append(f'missing or invalid section "{section}"')
            continue
        for key in keys:
            if key not in block:
                errors.append(f'{section}.{key}: missing (use "TODO(interview-skipped)" '
                              "only if the user explicitly refused the question)")
        for key in block:
            if key not in keys:
                errors.append(f"{section}.{key}: unknown key")
    if errors:
        raise RenderError("invalid answers file:\n  - " + "\n  - ".join(errors))

    project, stack = ans["project"], ans["stack"]
    for key in PROJECT_KEYS:
        if key in ("positive_reference", "negative_reference"):
            _check_reference(errors, f"project.{key}", project[key])
        elif key == "surfaces":
            _check_surfaces(errors, "project.surfaces", project[key])
        else:
            _check_text(errors, f"project.{key}", project[key])
    if isinstance(project.get("slug"), str) and not SLUG_RE.match(project["slug"]):
        errors.append("project.slug: must be lowercase ASCII words joined by "
                      "hyphens (e.g. my-project)")
    if stack["language"] not in LANGUAGES:
        errors.append(f"stack.language: must be one of {LANGUAGES}")
    if stack["has_frontend"] not in FRONTEND_CHOICES:
        errors.append(f"stack.has_frontend: must be one of {FRONTEND_CHOICES}")
    feats = stack["ai_features"]
    if (not isinstance(feats, list)
            or any(f not in AI_FEATURE_CHOICES for f in feats)
            or len(set(feats)) != len(feats)):
        errors.append("stack.ai_features: must be a list drawn from "
                      f"{AI_FEATURE_CHOICES} with no duplicates ([] = no AI)")
    for key in ("backend_framework", "vector_db", "llm_provider",
                "embeddings_model", "database"):
        _check_text(errors, f"stack.{key}", stack[key])
    _check_yes_no(errors, "stack.uses_devcontainer", stack["uses_devcontainer"])
    for key in SECURITY_KEYS:
        _check_yes_no(errors, f"security.{key}", ans["security"][key])
    for key in OPT_IN_KEYS:
        _check_yes_no(errors, f"opt_ins.{key}", ans["opt_ins"][key])
    agents = ans.get("agents")
    if (not isinstance(agents, list) or not agents
            or any(not isinstance(a, dict) or set(a) != {"name", "status"}
                   or a.get("name") not in AGENT_CHOICES
                   or a.get("status") not in AGENT_STATUSES
                   for a in agents)):
        errors.append(
            "agents: must be a non-empty list of "
            f'{{"name": one of {AGENT_CHOICES}, "status": one of {AGENT_STATUSES}}}')
    else:
        names = [a["name"] for a in agents]
        if len(set(names)) != len(names):
            errors.append("agents: duplicate agent names")
        if ans["opt_ins"]["codex_reviewer"] == "yes" and "codex" not in names:
            errors.append('opt_ins.codex_reviewer: "yes" requires "codex" in agents')
    if "features" not in ans:
        errors.append("features: missing (top-level, required)")
    else:
        _check_features(errors, ans["features"])
    if "design" not in ans:
        errors.append("design: missing (top-level; null when no frontend)")
    else:
        _check_design(errors, ans["design"], stack["has_frontend"])
    date = ans.get("date")
    if not isinstance(date, str) or not DATE_RE.match(date):
        errors.append("date: must be an ISO date string (YYYY-MM-DD)")
    if ans.get("weight") not in WEIGHTS:
        errors.append(f"weight: must be one of {WEIGHTS} (the project's factory "
                      "weight -- derived in the interview, confirmed at Phase 3)")
    if errors:
        raise RenderError("invalid answers file:\n  - " + "\n  - ".join(errors))

    # Normalize line endings in free text so output bytes are deterministic.
    for key in PROJECT_KEYS:
        if isinstance(project[key], str):
            project[key] = project[key].replace("\r\n", "\n").replace("\r", "\n")
    return ans


def load_profile(profile_dir: str) -> dict:
    path = os.path.join(profile_dir, "profile.json")
    if not os.path.isfile(path):
        raise RenderError(f"profile.json not found in {profile_dir}")
    with open(path, encoding="utf-8") as f:
        prof = json.load(f)
    errors = [f"profile.json: {k}: must be a string" for k in PROFILE_SCALARS
              if not isinstance(prof.get(k), str)]
    errors += [f"profile.json: {k}: must be a list of lines" for k in PROFILE_LISTS
               if not isinstance(prof.get(k), list)]
    notes = prof.get("notes")
    if not isinstance(notes, dict):
        errors.append("profile.json: notes: must be an object")
    else:
        errors += [f"profile.json: notes.{k}: must be a list of lines"
                   for k in PROFILE_NOTES if not isinstance(notes.get(k), list)]
    if errors:
        raise RenderError("invalid profile:\n  - " + "\n  - ".join(errors))
    return prof


