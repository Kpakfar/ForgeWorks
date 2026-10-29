# Placeholder substitution

Templates use `{{PLACEHOLDER}}` syntax. `render.py` performs every
substitution; these tables map each placeholder to the answer (or profile
value) that feeds it. Any new placeholder is added here, to the answers schema
(or `profile.json`), and to `render.py`'s mapping, together.

### Universal placeholders (asked or derived)

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | the conversation (name) |
| `{{PROJECT_GOAL}}` | the conversation (one-sentence goal) |
| `{{PROJECT_SLUG}}` | derived from the name: lowercase, hyphenated, valid package/module identifier |
| `{{PRIMARY_USER}}` | the conversation (who it's for) |
| `{{CORE_PROBLEM}}` | the conversation (the problem, why now) |
| `{{CORE_JOURNEY}}` | the conversation (the heart: the core user-visible flow, as steps) -- renders into `docs/PRD.md`'s journey section, and is also the raw material for the `features[].serves` "journey step" phrasing the agent writes by hand |
| `{{SUCCESS_MEASURE}}` | the conversation (what success looks like, concretely) |
| `{{RISKIEST_ASSUMPTION}}` | the conversation (the assumption that sinks the project if wrong) -- answers-file only (no template consumer in v4.0.0) |
| `{{REQ_AC_LIST}}` | the conversation (3-5 observable acceptance criteria) -- kept in the answers file as the raw `- [ ] **REQ-ACn:** <criterion>` lines; answers-file only (no template consumer in v4.0.0 -- no `docs/requirements.md` exists to render it into). These criteria are the source for each feature's `acceptance` array in Phase 4, not for this placeholder. |
| `{{NON_GOALS}}` | the conversation (bullet list; at least two concrete non-goals) |
| `{{OTHER_USERS}}` | the conversation (bullet list; `- none identified yet` if empty) -- answers-file only (no template consumer in v4.0.0) |
| `{{CONSTRAINT_TIME}}` | the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{CONSTRAINT_COST}}` | the conversation (includes LLM/API budget when AI is in scope) -- answers-file only (no template consumer in v4.0.0) |
| `{{CONSTRAINT_DATA}}` | the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{FIRST_MILESTONE}}` | the conversation -- derived date or `none set` |
| `{{DEPLOYMENT_TARGET}}` | the conversation (where this runs and is hosted) |
| `{{SCALE_EXPECTATIONS}}` | the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{INTEGRATIONS}}` | the conversation (bullet list; `- none` if none) -- answers-file only (no template consumer in v4.0.0) |
| `{{PAIN_POINT}}` | the conversation (positioning) |
| `{{PRODUCT_CATEGORY}}` | the conversation (positioning) |
| `{{CURRENT_ALTERNATIVE}}` | the conversation (positioning) |
| `{{KEY_BENEFIT}}` | the conversation (positioning) |
| `{{KEY_DIFFERENTIATOR}}` | the conversation (positioning) |
| `{{IN_SCOPE_LIST}}` | derived from the core journey + acceptance criteria (bullet list) |
| `{{SUCCESS_METRICS}}` | the success measure, rendered as 1-3 `- <metric> -- target` lines |
| `{{PRD_SURFACES}}` | derived: `project.surfaces` (bullet list; `- (no user-facing surfaces -- API/CLI product)` when empty) -- renders into `docs/PRD.md`'s Surfaces section |
| `{{READS_UNTRUSTED}}` | the security-sensitive answer (`yes`/`no`) -- answers-file only (no template consumer in v4.0.0; the security-profile line in `docs/SECURITY.md` is written directly by renderer rule 10, not through this placeholder) |
| `{{HOLDS_PRIVATE_DATA}}` | the security-sensitive answer (`yes`/`no`) -- answers-file only (no template consumer in v4.0.0), same as above |
| `{{ACTS_OUTWARD}}` | the security-sensitive answer (`yes`/`no`) -- answers-file only (no template consumer in v4.0.0), same as above |
| `{{E2E_BROWSER_INSTALL_STEP}}` | derived from the frontend answer + profile `e2e_browser_install` (renderer rule 12) |
| `{{LANGUAGE}}` | the conversation (language) |
| `{{HAS_FRONTEND}}` | the conversation (frontend?) |
| `{{BACKEND_FRAMEWORK}}` | inferred from the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{AI_FEATURES}}` | inferred from the conversation (comma-separated) |
| `{{VECTOR_DB}}` | inferred from the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{LLM_PROVIDER}}` | inferred from the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{EMBEDDINGS_MODEL}}` | inferred from the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{DATABASE}}` | inferred from the conversation -- answers-file only (no template consumer in v4.0.0) |
| `{{USES_DEVCONTAINER}}` | the conversation, or the documented default (`yes`) |
| `{{POSITIVE_REFERENCE_TEXT}}` | the conversation (codebase-shape reference, if offered) -- rendered line (Phase 4 renderer table, rule 5) |
| `{{NEGATIVE_REFERENCE_TEXT}}` | the conversation (codebase-shape anti-reference, optional) -- rendered line, may be empty |
| `{{DESIGN_REFERENCES}}` | the frontend visual-reference follow-up -- bullet list; empty string when `design` is `null` |
| `{{DESIGN_TONE}}` | the frontend visual-reference follow-up -- tone words; empty string when `design` is `null` |
| `{{DESIGN_ANTI_REFERENCE}}` | the frontend visual-reference follow-up -- anti-reference; empty string when `design` is `null` |
| `{{MEMORY_DOC_LINE}}` | derived from the mem0 opt-in (`templates/conditional/memory-doc-line.md`, or empty) |
| `{{AI_DISCIPLINE_BLOCK}}` | derived from the AI-features answer (`templates/conditional/ai-discipline.md`, or empty) |
| `{{CODEX_REVIEW_STEP}}` | derived from the codex-reviewer opt-in -- `templates/conditional/codex-review-step.md`, or empty |
| `{{CODEX_ROSTER_NOTE}}` | derived from the codex-reviewer opt-in -- `templates/conditional/codex-roster-note.md`, or empty |
| `{{AGENT_MATRIX}}` | derived from the agent roster -- per-agent sections from `templates/conditional/agents/`, joined |
| `{{DATE}}` | today, ISO format (`date` in the answers file) |

`opt_ins.explanations`, `opt_ins.seed_gotchas`, and `opt_ins.mem0` have no placeholder of their own: they are switches in the answers file's `opt_ins` section that turn renderer rules 6-8 on or off.

Rows marked **answers-file only (no template consumer in v4.0.0)** above are still asked (or inferred), still required by the answers schema, and still land in `render.py`'s mapping -- `render.py` fails on an unmapped placeholder, so keeping the mapping entry is required either way, not optional cleanup. They simply have no `{{...}}` occurrence left in any file under `templates/core/` or `templates/profiles/` to substitute into, most often because the v3 redesign retired the doc that used to render them (e.g. `docs/requirements.md`) in favor of `docs/features.json` and `docs/PRD.md`. Removing the schema requirement and mapping entry for any of them is a breaking answers-schema change (touches `render_schema.py` and all nine golden fixtures) and is deliberately out of scope here -- if a row's answer is never used anywhere (not even to inform a derived field or a hand-written doc section), that is a signal to prune it in a dedicated pass, not silently.

### Language-derived placeholders (from the profile)

The renderer reads these from `templates/profiles/<lang>/profile.json` (the
machine-readable copy of the YAML blocks below -- keep the two in sync; the
golden-fixture CI cross-checks the load-bearing values).

| Placeholder | Filled from language profile |
|---|---|
| `{{LANGUAGE_VERSION}}` | profile.language_version |
| `{{PACKAGE_MANAGER}}` | profile.package_manager |
| `{{MANIFEST_FILE}}` | profile.manifest_file |
| `{{INSTALL_COMMAND}}` | profile.install_command |
| `{{ADD_DEP_COMMAND}}` | profile.add_dep_command |
| `{{QA_COMMAND}}` | profile.qa_command |
| `{{FIX_COMMAND}}` | profile.fix_command |
| `{{E2E_COMMAND}}` | profile.e2e_command |
| `{{TEST_RUNNER}}` | profile.test_runner |
| `{{TEST_COMMAND}}` | profile.test_command |
| `{{LINT_TOOL}}` | profile.lint_tool |
| `{{LINT_COMMAND}}` | profile.lint_command |
| `{{FORMAT_TOOL}}` | profile.format_tool |
| `{{FORMAT_COMMAND}}` | profile.format_command |
| `{{TYPE_TOOL}}` | profile.type_tool |
| `{{TYPE_COMMAND}}` | profile.type_command |
| `{{PRECOMMIT_INSTALL_COMMAND}}` | profile.precommit_install_command |
| `{{TEST_PATH_REGEX}}` | profile.test_path_regex -- the pattern `scripts/tamper_check.py` uses to recognize a test-file path for the tamper guard |
| `{{INLINE_TEST_REGEX}}` | profile.inline_test_regex -- for a language whose unit tests live inside source files (Rust), the pattern `scripts/tamper_check.py` looks for in a source file's removed lines; empty when tests live only in test files |
| `{{SOURCE_SUFFIXES}}` | profile.source_suffixes -- the set literal of source extensions `scripts/dup_check.py` scans for the duplication gate |
| `{{CI_SETUP_STEPS}}` | profile.ci_setup_steps (multi-line YAML block) |
| `{{LANGUAGE_PRECOMMIT_HOOKS}}` | profile.precommit_hooks (multi-line YAML block) |
| `{{LIBRARY_DOCS_URLS}}` | profile.library_docs_urls (markdown list) |
| `{{TYPE_ANNOTATION_NOTES}}` | profile.notes.type_annotations |
| `{{IMPORT_NOTES}}` | profile.notes.imports |
| `{{ASYNC_NOTES}}` | profile.notes.async |
| `{{ERROR_NOTES}}` | profile.notes.errors |
| `{{CONFIG_NOTES}}` | profile.notes.config |
| `{{LOGGING_NOTES}}` | profile.notes.logging |
| `{{TEST_LAYOUT_NOTES}}` | profile.notes.test_layout |
| `{{PRECOMMIT_HOOKS_NOTES}}` | profile.notes.precommit_hooks |

