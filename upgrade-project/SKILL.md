---
name: upgrade-project
description: Upgrade an EXISTING project bootstrapped from an older ForgeWorks release to the current structure without clobbering hand-filled content. Reconciles the project against a fresh copy of the template: copies missing always-on files, grafts new AGENTS.md rule blocks and subagent sections, applies the language tooling delta, migrates the v4 ledger into features.json state, and reports the rest. Non-destructive and idempotent. Use when a project already has a generated AGENTS.md and the user says "upgrade", "/upgrade-project", "update the harness", or "sync the template". Not for an empty directory -- that is /init-project.
---

# upgrade-project

Brings an **existing** generated project up to the current template. The hard
problem: `AGENTS.md`, `docs/`, and the subagents hold hand-filled content, so
the upgrade cannot overwrite. It reconciles.

## Principles

- **Non-destructive.** Create only what is absent; insert into existing files, never replace them wholesale. The one exception is the v3->v4 migration (Phase 3-D), which replaces the v3 harness after the owner's accept.
- **Idempotent.** Every step checks "already present?" first. A second run changes nothing.
- **Automate the safe part, assist the rest.** Placeholder-free files copy automatically. Merges into hand-edited files are computed first and approved as one batched report (Phase 4).
- **Reconcile against the live template.** The skill diffs the project against a fresh `templates/core` plus the project's own `templates/profiles/<lang>`, so a file added to the template later is picked up without editing this skill.

## Phase 0: Confirm and make it safe

1. Confirm this is a generated project (a non-bootstrap `AGENTS.md`). If not, stop: that is `init-project`'s job.
2. Work in a dedicated worktree, never by switching branches in the shared checkout (another session may be working there):
   ```bash
   git worktree add ../<project>-upgrade -b chore/upgrade-template
   cd ../<project>-upgrade
   ```
   When done, the user merges the branch and removes the worktree.
3. If `git status` shows changes you did not make, stop until the user says whose they are.

## Phase 1: Recover context

Recover from the project, ask only for what you cannot detect (2-3 questions at most):

- **Project name and language** from the manifest (`pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`).
- **AI features?** A `prompts/` dir, an LLM SDK in the manifest, or an `<ai-discipline>` block. Confirm yes/no.
- **Agent roster** from `docs/agents.json`; absent means Claude-only. Governs the CC-fence rule and roster gating.
- **mem0?** `docs/memory.md`, a `<memory>` block, or `mem0ai` in the manifest. Absent: ask once (default no).
- **Quality-gate command** from `docs/language-standards.md` or the manifest scripts.
- **Codex?** An existing "Second opinion (Codex)" section in `reviewer.md`, or a Codex roster note, means opted in: keep it, never remove it on a "no". No trace: ask once.
- **From-version** from `.claude/.template-version`. Rewritten only in Phase 4 after success.

## Phase 2: Fetch the current template

```bash
npx --yes degit@2.8.4 Kpakfar/ForgeWorks/init-project/templates/core#v5.1.0 /tmp/upgrade-core --force
npx --yes degit@2.8.4 Kpakfar/ForgeWorks/init-project/templates/profiles/<lang>#v5.1.0 /tmp/upgrade-profile --force
npx --yes degit@2.8.4 Kpakfar/ForgeWorks/init-project#v5.1.0 /tmp/upgrade-skill --force
```

Never pull another language's profile. A language with no profile folder reconciles `core/` only; the toolchain stays the user's. Conditional block texts live in `/tmp/upgrade-skill/templates/conditional/`. Reconcile against this skill's released tag (`v5.1.0`), not `main`.

## Phase 3: Reconcile

Route by the from-version: below 3.0.0, install the `v3.0.0`-tagged upgrade skill first. Below 4.0.0, run **Phase 3-D** instead of A-C, then the v5 delta in 3-C. On 4.x or later, run A-C-E-F below.

**A. File ABSENT in the project (additive).** Apply roster and frontend gating first, exactly like `render.py`: `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, and the `CLAUDE.md` symlink are not additive without `claude-code` in the roster; `docs/design/` and the tokens file are not additive without a frontend. Then:
- No `{{...}}` placeholders: copy verbatim, `chmod +x` any `.sh`.
- Only recoverable placeholders (`{{PROJECT_NAME}}`, `{{LANGUAGE}}`, `{{DATE}}`, `{{TEST_PATH_REGEX}}`, `{{QA_COMMAND}}`, `{{SOURCE_SUFFIXES}}`, `{{CODEX_REVIEW_STEP}}`): substitute from Phase 1 and the fetched `profile.json`, copy, then apply the fence rules below.
- Unresolvable placeholders: never half-write one. Report "add manually" with the template path.
- Interview-sourced placeholders (mostly `docs/PRD.md`): queue for the Phase 3-E mini-interview.

Special cases:
- `.claude/settings.json`: merge every `PreToolUse` hook the template ships into the existing `hooks` object; never replace the file.
- **AI fences** (`<!-- AI-*-START/END -->` in `docs/SECURITY.md` and `reviewer.md`): AI on, drop only the markers; AI off, drop the block. **CC fences** (`<!-- CC-*-START/END -->`, keyed on `claude-code` in the roster): same mechanic.
- Python manifest: `pyproject.toml.example` is the merge source for the existing `pyproject.toml`, never a new file.
- `.devcontainer/`: respect the original opt-out; note availability once.
- `docs/agents.md` + `docs/agents.json`: cannot be recovered. Ask the roster question and write both.

**B. File PRESENT in both (merge target).** Insert what is new, preserve what the project filled in.
- `AGENTS.md`: reconcile by `<!-- FW-BLOCK: <name> vX.Y.Z -->` markers, not judgment. Current block names: `project`, `commands`, `etiquette`, `hard-rules`, `tiers`, `communication`, `context`, `learning`, `roster`, plus the conditional `ai-discipline` and `memory`. Block absent: insert at its template position. Older marker version: show both versions side by side once in the Phase 4 report; the user chooses. Current version: skip. A block with no markers on a 4.x project: match by tag, wrap with markers at the from-version, then re-enter the rule. Conditional blocks take their text from `/tmp/upgrade-skill/templates/conditional/` and only when the project uses the feature. Flag the retired `risk-tiers` block for removal if still present.
- Subagents (`reviewer.md`, `utility.md`) and the three skills: template-owned procedure files. If the project's copy is byte-identical to an older release, queue the current version as a straight update; if hand-edited, show the diff and let the user choose. Never assume the template is ahead; the project may carry a fix (report it upstream).
- Any other file in both (hooks, `.mcp.json`, workflows, doc templates): same rule.

**C. Tooling delta (language-gated).** Compare the fetched profile's manifest, scripts, and CI against the project's and surface the diffs. High-value checks per language:
- **Python**: `e2e` and `security` pytest markers registered; `pytest-playwright` in the dev group; the fast gate runs `pytest -m "not e2e"`; `scripts/linecap.sh` runs first in `scripts/qa.sh`; `[tool.mypy] mypy_path = "src"`; no stray `src/__init__.py` under the flat-import convention.
- **TypeScript**: `qa`/`fix`/`e2e` npm scripts and a non-vulnerable dev-dep set match the profile; `eslint.config.js` carries the `max-lines` rule.
- **Go**: a supported Go in `go.mod`; the pinned `golangci-lint` v2 in CI; `scripts/linecap.sh` first in `qa.sh`; `go test -race` in both runners.
- **Rust**: `qa.sh` runs linecap, `cargo fmt --check`, clippy with `-D warnings`, `cargo check`, `cargo test`; e2e tests `#[ignore]`-tagged and run only by `scripts/e2e.sh`; `rust-toolchain.toml` pins the toolchain.

Language-independent deltas, oldest first (each idempotent; skip what already landed):

- *Since v4.1.0*: `scripts/dup_check.py` (substitute `{{SOURCE_SUFFIXES}}`) and the `dup-check` job; run `python3 scripts/dup_check.py --baseline` so existing findings stop failing while new ones do, and add a burn-down `features.json` entry. `scripts/resume.py` and the `resume-check` job. The `checkpoint-budget` job.
- *Since v4.4.2*: ask the owner one question, `weight: lite or full?`; add `weight` and `model_tiers` to `docs/agents.json` (Claude roster: `mechanical: haiku`, `standard: sonnet`, `judgment: inherit`; other rosters: TODOs). If lite, apply the template's `# FW-LITE-START/END`-fenced lines to `qa.yml` without the markers. `scripts/prune.py` and its `--check` step in the `docs-budget` job. `docs/proposals-ideas.md` is retired: promote anything live to todo entries and delete it.
- *Since v4.6.0*: `.claude/hooks/tree-claim.sh` (claude-code rosters) merged into `settings.json`; `.claude/worktrees/` and `.claude/.tree-claim` in `.gitignore`.
- *Since v4.7.0*: `scripts/skills_doctor.py` and the fetched `scripts/factory_doctor.sh`. Run the skills doctor once and put its findings first in the Phase 4 report; the fix (`/plugin`) is the owner's.
- *Since v5.0.0 (the lean loop)*: the loop's state moved from `docs/LEDGER.md` into each `features.json` entry (`phase`, `next`), deviations moved into the entry's `notes`, and `docs/archive/` is retired.
  1. Copy `scripts/feature.py`; replace `scripts/resume.py`, `scripts/prune.py`, `scripts/backlog.py`, `scripts/features_check.py` with the fetched versions (template-owned; diff first).
  2. For the in-progress feature (at most one), read its last ledger line and set `phase=<grill|red|green|review>` and `next="..."` with `python3 scripts/feature.py <id> ...`. Every other feature's ledger lines describe closed work; the commits are the record. Delete `docs/LEDGER.md`.
  3. For each open feature's `docs/deviations.md` lines, append them to that feature's `notes` verbatim (`notes+=`). Delete `docs/deviations.md`.
  4. Delete `docs/archive/` after the same citation grep as 3-F.
  5. Replace the `docs-budget`, `checkpoint-budget`, and `resume-check` jobs in `qa.yml` with the fetched versions (this release changes the `AGENTS.md` cap from lines to characters and drops the retired files; show the diff).
  6. Replace the `iteration` skill (now `SKILL.md` plus `reference/dispatch.md`), `reviewer.md`, `utility.md`, `security-review`, `tech-debt`, `docs/plans/README.md`, and the PR template with the fetched versions; graft every `AGENTS.md` block at v5.0.0 through 3-B (all nine blocks changed: shorter, and the conflicts with the harness's own system prompt removed). A hand-edited `AGENTS.md` must land under the new character cap; delete stale sentences rather than rewrite them.
- *Since v5.1.0 (a tree per session)*: replace `.claude/hooks/tree-claim.sh` with the fetched version (claude-code rosters). The old hook read the claim from the checkout the session was launched from, so a session that moved into its own worktree stayed blocked. Copy `scripts/land.sh`, and `.worktreeinclude` for claude-code rosters. Replace `scripts/factory_doctor.sh` and the `iteration` skill. Graft the `etiquette` block at v5.1.0 through 3-B.

**E. Mini-interview.** Collect every queued interview-sourced placeholder, dedupe, ask only those questions in one message (using the Phase 2 wording from `init-project/SKILL.md`), substitute, write. The upgrade ends with zero `{{...}}` on disk. A declined question writes `TODO(interview-skipped)`.

**F. Doc compaction.** The only step that edits project content; every deletion goes in the Phase 4 report as a named list and applies on the owner's yes. Bring each budgeted doc under its cap by deleting, not by moving bytes: `docs/SECURITY.md` (fold per-feature subsections back into the fixed sections; delete surfaces the project no longer has), `docs/gotchas.md` (entries the code now makes impossible), plans for merged features (`docs/plans/archive/` is retired; move any plan whose feature is not done back to `docs/plans/`), mockups no entry cites, probes nothing cites (`grep -rn "docs/probes/" .` first). Report before/after sizes. Within 5% of a cap is shaving, not compacting.

### Phase 3-D: v3 -> v4 migration (replace, not accumulate)

Only for a project below 4.0.0, after the owner's accept, and idempotent (copy-if-absent, graft only markers not at the current version, remove-if-present). The removal step runs last so the project always has a working harness. Apply roster and frontend gating throughout.

1. **Copy in the current files**: the `iteration` skill, `.claude/agents/reviewer.md` (claude-code roster only), `docs/BACKLOG.md`, `docs/PRD.md` (skeleton; step 3 distills the retired `PRODUCT_VISION.md` into it), every `scripts/*` the fetched template has (replace `features_check.py`; the v3 copy enforces retired tiers), `scripts/tamper_check.py` (substitute `{{TEST_PATH_REGEX}}`), and every CI job the fetched `qa.yml` carries that the project lacks. Overwrite the `security-review` and `tech-debt` skills with the fetched text.
2. **Graft the `AGENTS.md` blocks** (3-B rules). `risk-tiers` is replaced by `tiers`; `communication` and `context` are new inserts between `tiers` and `learning`.
3. **Carry, never regenerate, project content**: `features.json` entries (add `"surface": "none"`; remap `tier`: `light` -> `chore`, `standard`/`high-risk` -> `feature`), plans for features not yet done, gotchas, mockups, SECURITY.md project sections. Run 3-F over the carried content. Distill `PRODUCT_VISION.md` into `docs/PRD.md`.
4. **Remove superseded files** after confirming with the owner: `.claude/skills/slice/`, `design-loop/`, `select-agents/`, `.claude/agents/implementer.md`, `code-reviewer.md`, `design-reviewer.md`, `security-reviewer.md`, `docs/PRODUCT_VISION.md`, `docs/plans/archive/`, and a stale `.claude/skills/init-project/`.
5. **Fresh-render diff.** Render a fresh tree from a reconstructed answers file (ask for `surfaces`, or `TODO(interview-skipped)`), diff the harness files against the project, and report each difference as: matches fresh render / project-specific keeper / leftover v3 debris.
6. **Fallback.** Heavy drift means recommend "fresh render + carry-over" instead of a half-migration, and stop for the owner's decision.

## Phase 4: One report, one approval, then verify and stamp

1. Compute the entire change set. Present one report with five buckets: copy verbatim, graft (blocks by name), substitute (with values), needs your answer, superseded (flagged for removal). Collect the answers and a single yes.
2. Apply everything; `chmod +x` new scripts and hooks.
3. Ensure `docs/plans/`, `docs/probes/`, and (frontend) `docs/design/mockups/` exist with current READMEs.
4. Run the language quality gate, `python3 scripts/features_check.py`, `python3 scripts/resume.py --check`, and `python3 scripts/prune.py --check`; fix any breakage the upgrade introduced.
5. Only after all pass, write the new version to `.claude/.template-version`.
6. `rm -rf .claude/skills/upgrade-project`. A stale copy is what the next upgrade must not reconcile against; the installer re-fetches the current one.
7. Close with: "Upgraded <from> -> <to> in one run. Review the diff and commit on your branch. Nothing was overwritten without being shown first."

## Failure modes

- **Uninitialized directory.** Stop; run `/init-project`.
- **`degit` fails.** Stop with the cause; the upgrade needs the current template.
- **`AGENTS.md` heavily rewritten.** Show the missing blocks and let the user place them.
- **Re-run after a partial upgrade.** Safe; every step skips what already landed.

## Note for template maintainers

A new always-on, placeholder-free file in `core/` is picked up automatically. Touch this skill only for: a file with tooling placeholders (extend 3-A), a tooling-delta step (extend 3-C), a new `AGENTS.md` block that needs special placement (note it in 3-B), or a structural change old projects must migrate (a dated 3-C delta, like v5.0.0's). New interview-sourced placeholders go in the 3-A discovery list so 3-E asks for them.
