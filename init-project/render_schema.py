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

LANGUAGES = ("python", "typescript", "go", "rust")
FRONTEND_CHOICES = ("yes-spa", "yes-minimal", "no")
AI_FEATURE_CHOICES = ("rag", "agents", "evals", "streaming")

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
)
STACK_KEYS = (
    "language", "has_frontend", "backend_framework", "ai_features",
    "vector_db", "llm_provider", "embeddings_model", "database",
    "uses_devcontainer",
)
SECURITY_KEYS = ("reads_untrusted", "holds_private_data", "acts_outward")
OPT_IN_KEYS = ("explanations", "seed_gotchas", "mem0", "codex_reviewer")

PROFILE_SCALARS = (
    "display_name", "language_version", "package_manager", "manifest_file",
    "install_command", "add_dep_command", "qa_command", "fix_command",
    "e2e_command", "e2e_browser_install", "test_runner", "test_command",
    "lint_tool", "lint_command", "format_tool", "format_command", "type_tool",
    "type_command", "precommit_install_command",
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


def validate_answers(ans: object) -> dict:
    """Validate the answers file against the documented schema. Fail closed."""
    errors: list[str] = []
    if not isinstance(ans, dict):
        raise RenderError("answers file: top level must be a JSON object")
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
    date = ans.get("date")
    if not isinstance(date, str) or not DATE_RE.match(date):
        errors.append("date: must be an ISO date string (YYYY-MM-DD)")
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


