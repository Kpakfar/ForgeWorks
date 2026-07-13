#!/usr/bin/env python3
"""Render smoke test: substitute core + each complete profile with safe values
and assert NO leftover {{PLACEHOLDER}} remains, and the manifest landed.

This proves template *completeness* (every placeholder used is fillable) and
feeds the per-profile CI gate runs via --emit. The real generation path is
init-project/render.py; its conditional matrix and hostile-value escaping are
locked byte-for-byte by .github/scripts/golden_test.py. Run from the repo root.
"""

from __future__ import annotations

import glob
import os
import re
import shutil
import sys
import tempfile

T = "init-project/templates"

PROFILE = {
    "python": dict(QA_COMMAND="uv run qa", FIX_COMMAND="uv run fix",
                   E2E_COMMAND="bash scripts/e2e.sh", MANIFEST_FILE="pyproject.toml",
                   INSTALL_COMMAND="uv sync", E2E_BROWSER_INSTALL="x",
                   PRECOMMIT_INSTALL_COMMAND="uv run pre-commit install",
                   LANGUAGE_PRECOMMIT_HOOKS="- id: ruff"),
    "typescript": dict(QA_COMMAND="npm run qa", FIX_COMMAND="npm run fix",
                       E2E_COMMAND="npm run e2e", MANIFEST_FILE="package.json",
                       INSTALL_COMMAND="npm install", E2E_BROWSER_INSTALL="x",
                       PRECOMMIT_INSTALL_COMMAND="", LANGUAGE_PRECOMMIT_HOOKS=""),
    "go": dict(QA_COMMAND="bash scripts/qa.sh", FIX_COMMAND="bash scripts/fix.sh",
               E2E_COMMAND="bash scripts/e2e.sh", MANIFEST_FILE="go.mod",
               INSTALL_COMMAND="go mod download", E2E_BROWSER_INSTALL="",
               PRECOMMIT_INSTALL_COMMAND="", LANGUAGE_PRECOMMIT_HOOKS=""),
    "rust": dict(QA_COMMAND="bash scripts/qa.sh", FIX_COMMAND="bash scripts/fix.sh",
                 E2E_COMMAND="bash scripts/e2e.sh", MANIFEST_FILE="Cargo.toml",
                 INSTALL_COMMAND="cargo fetch", E2E_BROWSER_INSTALL="",
                 PRECOMMIT_INSTALL_COMMAND="", LANGUAGE_PRECOMMIT_HOOKS=""),
}

COMMON = dict(
    PROJECT_NAME="Smoke", PROJECT_SLUG="smoke", PROJECT_GOAL="a goal",
    PRIMARY_USER="dev", CORE_PROBLEM="x", CORE_JOURNEY="1. x", SUCCESS_MEASURE="x",
    RISKIEST_ASSUMPTION="x", NON_GOALS="- x", LANGUAGE="L", LANGUAGE_VERSION="1",
    HAS_FRONTEND="no", BACKEND_FRAMEWORK="none", AI_FEATURES="none", VECTOR_DB="none",
    LLM_PROVIDER="none", EMBEDDINGS_MODEL="none", DATABASE="none", USES_DEVCONTAINER="no",
    DATE="2026", PACKAGE_MANAGER="pm", ADD_DEP_COMMAND="add", TEST_RUNNER="t",
    TEST_COMMAND="t", LINT_TOOL="l", LINT_COMMAND="l", FORMAT_TOOL="f", FORMAT_COMMAND="f",
    TYPE_TOOL="ty", TYPE_COMMAND="ty", CI_SETUP_STEPS="# ci", LIBRARY_DOCS_URLS="- d",
    AI_DISCIPLINE_BLOCK="", CODEX_REVIEW_STEP="", CODEX_ROSTER_NOTE="", MEMORY_DOC_LINE="",
    POSITIVE_REFERENCE_TEXT="x", NEGATIVE_REFERENCE_TEXT="",
    REQ_AC_LIST="- [ ] **REQ-AC1:** x", OTHER_USERS="- x", CONSTRAINT_TIME="x",
    CONSTRAINT_COST="x", CONSTRAINT_DATA="x", FIRST_MILESTONE="x",
    DEPLOYMENT_TARGET="x", SCALE_EXPECTATIONS="x", INTEGRATIONS="- x",
    PAIN_POINT="x", PRODUCT_CATEGORY="x", CURRENT_ALTERNATIVE="x",
    KEY_BENEFIT="x", KEY_DIFFERENTIATOR="x", IN_SCOPE_LIST="- x",
    SUCCESS_METRICS="- x", READS_UNTRUSTED="no", HOLDS_PRIVATE_DATA="no",
    ACTS_OUTWARD="no", E2E_BROWSER_INSTALL_STEP="# no browser",
    **{k: "x" for k in ("TYPE_ANNOTATION_NOTES", "IMPORT_NOTES", "ASYNC_NOTES",
                        "ERROR_NOTES", "CONFIG_NOTES", "LOGGING_NOTES",
                        "TEST_LAYOUT_NOTES", "PRECOMMIT_HOOKS_NOTES")},
)

# The rendered tree simulates a NO-AI project (AI_DISCIPLINE_BLOCK=""), so every
# AI fence is stripped the same way /init-project Phase 4 rule 5 strips them on a
# no-AI answer -- in EVERY file that carries one (SECURITY.md, requirements.md,
# implementer.md, code-reviewer.md, and any future fenced file).
FENCE = re.compile(r"<!-- AI-[A-Z]+-START -->.*?<!-- AI-[A-Z]+-END -->\n?", re.S)

# Hidden files/dirs (.claude, .github, .env.example, ...) that MUST be visited.
# glob('**/*') silently skips dotfiles, so we walk instead and assert coverage.
SENTINELS = (".claude/hooks/quality-gate.sh", ".github/workflows/qa.yml", ".env.example")


def all_files(root: str) -> list[str]:
    out = []
    for dirpath, _, names in os.walk(root):  # os.walk includes dotfiles/dirs
        out += [os.path.join(dirpath, n) for n in names]
    return out


def render(lang: str, out: str) -> list[str]:
    shutil.copytree(f"{T}/core", out)
    for root, _, files in os.walk(f"{T}/profiles/{lang}"):
        rel = os.path.relpath(root, f"{T}/profiles/{lang}")
        for fn in files:
            if rel == "." and fn == "profile.json":
                continue  # renderer input, never part of a generated project
            d = os.path.join(out, rel)
            os.makedirs(d, exist_ok=True)
            shutil.copy2(os.path.join(root, fn), os.path.join(d, fn))
    if lang == "python" and os.path.exists(f"{out}/pyproject.toml.example"):
        os.rename(f"{out}/pyproject.toml.example", f"{out}/pyproject.toml")
    mapping = {**COMMON, **PROFILE[lang]}
    for f in all_files(out):
        try:
            c = open(f, encoding="utf-8").read()
        except (UnicodeDecodeError, IsADirectoryError):
            continue
        c = FENCE.sub("", c)
        for k, v in mapping.items():
            c = c.replace("{{%s}}" % k, v)
        open(f, "w", encoding="utf-8").write(c)
    leftover = []
    for f in all_files(out):
        try:
            leftover += re.findall(r"\{\{[A-Z0-9_]+\}\}", open(f, encoding="utf-8").read())
        except (UnicodeDecodeError, IsADirectoryError):
            pass
    if not os.path.exists(os.path.join(out, mapping["MANIFEST_FILE"])):
        leftover.append("<missing manifest %s>" % mapping["MANIFEST_FILE"])
    # Assert the hidden files were actually present and visited.
    for s in SENTINELS:
        if not os.path.exists(os.path.join(out, s)):
            leftover.append("<sentinel not rendered: %s>" % s)
    return leftover


def main() -> int:
    # --emit <lang> <dir>: render ONE merged core+profile tree to <dir> so CI can
    # run the language's real quality gate on the same shape a generated project
    # has (profile-only runs miss core/profile interactions, e.g. a formatter
    # that scans core files).
    if len(sys.argv) == 4 and sys.argv[1] == "--emit":
        lang, out = sys.argv[2], sys.argv[3]
        left = render(lang, out)
        if left:
            print(f"FAIL [{lang}] leftover/missing: {sorted(set(left))}")
            return 1
        print(f"ok   [{lang}] merged core+profile rendered to {out}")
        return 0
    rc = 0
    for lang in ("python", "typescript", "go", "rust"):
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "proj")
            left = render(lang, out)
            if left:
                print(f"FAIL [{lang}] leftover/missing: {sorted(set(left))}")
                rc = 1
            else:
                print(f"ok   [{lang}] rendered clean, manifest present")
    return rc


if __name__ == "__main__":
    sys.exit(main())
