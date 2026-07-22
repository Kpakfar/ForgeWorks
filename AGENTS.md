# AGENTS.md -- developing the template itself

This file is the constitution for working *on* `ForgeWorks`. It is for contributors and AI agents editing this repo. End users bootstrapping a new project from the template should read `README.md` and `docs/how-to-use.md` instead.

`CLAUDE.md` symlinks to this file. Personal / WIP notes go in `CLAUDE.local.md` (gitignored).

<purpose>
`ForgeWorks` is a one-command bootstrapper for engineering projects. It is not a starter app. Every file the template ships becomes part of someone else's repo, so every edit must be reviewed through that lens: would a stranger landing on a generated project understand it, and is anything project- or stack-specific leaking in by accident?
</purpose>

<repo-architecture>
Three pieces, each with a single responsibility:

- `bootstrap/install.sh` -- runs in an empty target folder. Validates environment (curl, git, npx), drops `AGENTS.md` (bootstrap mode) into the target, and installs the `/init-project` skill via `npx degit`. Knows nothing about stacks.
- `bootstrap/AGENTS.md` -- the bootstrap-mode constitution that lands in target projects. Tells the agent "this project is uninitialized; run `/init-project`."
- `init-project/SKILL.md` -- the interview skill. Runs in the target project after install. Asks A1-A10 (product discovery) + B1-B12 (stack and opt-ins), writes the answers to `docs/_init-answers.json` (schema documented in Phase 4), runs the renderer, then installs deps (Phase 4.5, the only agent-executed generation step -- it runs package managers).
- `init-project/render.py` -- the deterministic renderer (stdlib Python, plain string substitution, no template engine). Takes `--answers/--core/--profile/--out` and executes every substitution and conditional rule: placeholder table, AI-discipline block, AI fences, style references, mem0/memory block, gotchas seed, explanations/devcontainer opt-outs, Codex conditionals, JSON/TOML escaping of hostile answers, multi-line re-indent, manifest `.example` rename, `CLAUDE.md` symlink, `chmod +x`, `.claude/.template-version` stamp. Same answers, same bytes; it fails closed on invalid answers or any leftover `{{...}}`.
- `init-project/templates/core/` -- the language-free files every project gets (AGENTS.md, docs/, security files, `.mcp.json`, CI shape, README, .env.example). Uses `{{PLACEHOLDER}}` substitution.
- `init-project/templates/conditional/` -- the canonical texts of the conditional blocks (`ai-discipline.md`, `memory-block.md`, `memory-doc-line.md`, `codex-review-step.md`, `codex-roster-note.md`, `gotchas-seed.md`). `render.py` reads them; SKILL.md only points at them. Edit block text HERE.
- `init-project/templates/profiles/<lang>/` -- one folder per language with its manifest, toolchain, `scripts/` (or package scripts), green scaffold, dev container, `.gitignore`, (Python only) pre-commit config, and `profile.json` -- the machine-readable profile values `render.py` substitutes (kept in sync with the SKILL.md `<language-profiles>` YAML; `profile.json` is renderer input and never copied into a generated project). A generated project = `core/` + exactly one profile, so no other language's files ever leak in. Python, TypeScript, Go, and Rust are complete; "Other" is not built yet.
- `.github/fixtures/golden/` -- six answers fixtures spanning the conditional matrix (AI/no-AI, devcontainer, opt-ins, hostile values) plus committed expected trees under `expected/<name>/`. The CI `golden-fixtures` job (`.github/scripts/golden_test.py`) re-renders each fixture and compares byte-for-byte; `--update` regenerates the trees after an intentional template change.
- `upgrade-project/SKILL.md` -- the brownfield counterpart to `init-project`. Runs in an EXISTING generated project and reconciles it to the current template (copies missing always-on files, grafts new `AGENTS.md` rule blocks and subagent sections without overwriting, applies the tooling delta, reports the rest). `bootstrap/install.sh` installs this skill instead of `init-project` when it detects an already-generated project.
- `VERSION` -- the template's version (e.g. `2.3.0`). The bootstrap stamps it into a generated project at `.claude/.template-version` (`render.py` writes the fallback if the stamp is missing); `upgrade-project` reads it for the from->to report.

The split is sharp: `bootstrap/` is dumb and stack-blind. `init-project/SKILL.md` is the greenfield interviewer and `render.py` its deterministic engine; `upgrade-project/SKILL.md` is the brownfield brain. `templates/core/` + `templates/profiles/` + `templates/conditional/` are the body.
</repo-architecture>

<editing-the-template>
When editing files in `init-project/templates/`:

- **`core/` is language-free.** Examples, conventions, and rule wording in `templates/core/` (especially `core/AGENTS.md`) must work for any language. If you write "Pydantic", "npm", "cargo", or any toolchain name in `core/` outside the conditional `<ai-discipline>` block, it is leakage -- lift it to the language's `<language-profiles>` YAML in `SKILL.md`, into `templates/profiles/<lang>/`, or to a conditional block. Anything language-specific (manifest, scripts, scaffold, dev container, `.gitignore`, pre-commit) lives in `templates/profiles/<lang>/`, never in `core/`.
- **AI-specific rules.** Live in the `<ai-discipline>` block (`templates/conditional/ai-discipline.md`), rendered only when at least one AI feature is selected (B4). Do NOT add AI examples to `<architecture-discipline>`.
- **Placeholders.** Use `{{UPPER_SNAKE}}` for substituted values. Every placeholder must be listed in `SKILL.md`'s placeholder table with its source (a Q number or a derived rule) AND implemented in `render.py`'s mapping (an unknown placeholder is a render error). After any template change, regenerate the golden expected trees (`golden_test.py --update`) and commit them with it -- the golden job diffs them byte-for-byte.
- **User-fillable slots.** Use literal text like `*<target user>*` or `TODO`. Do NOT use `{{...}}` for slots the user is meant to fill after generation; the renderer fails closed on any unresolved `{{...}}`.
- **Conditional files.** Files that should NOT ship when an opt-in is `no` (`docs/explanations/`, `docs/memory.md`) live in the template folder unconditionally; `render.py` skips them when the opt-in is off (see `skip_file`). New conditional files follow the same pattern: add the skip rule in `render.py` and cover both states in the golden fixtures.
- **Conditional block texts.** The sometimes-rendered block texts live in `templates/conditional/`; `render.py` reads them and `SKILL.md` Phase 4 points at them. Never re-inline them into SKILL.md.
- **Conditional content inside always-on files.** Some always-on files carry AI-only sections fenced with HTML-comment markers; `render.py` keeps or strips them by B4 (renderer rule 4: markers follow the `<!-- AI-<NAME>-START/END -->` shape and are handled generically). Current fences: `<!-- AI-SECURITY-START/END -->` + `<!-- AI-REDTEAM-START/END -->` in `docs/SECURITY.md`, `<!-- AI-FEATURES-START/END -->` in `docs/requirements.md`, `<!-- AI-IMPL-START/END -->` in `.claude/agents/implementer.md`, `<!-- AI-REVIEW-START/END -->` in `.claude/agents/code-reviewer.md`. A second family, `<!-- CC-<NAME>-START/END -->`, is keyed on `claude-code` being in the B13 roster (renderer rule 18); current fence: `<!-- CC-TREE-START/END -->` in `docs/structure.txt`. Fence any future sometimes-on content the same way (the renderer picks each family up automatically) and register the new marker in `upgrade-project/SKILL.md` Phase 3-A.
- **FW-BLOCK markers.** Every rule block in `templates/core/AGENTS.md` is wrapped in `<!-- FW-BLOCK: <name> vX.Y.Z -->` ... `<!-- /FW-BLOCK: <name> -->` markers. They ship into generated projects and are what makes `upgrade-project`'s block grafting deterministic (absent -> insert; older version -> show side-by-side; current -> skip). When you edit a block's content, bump the version in its opening marker to the release that ships the change. New blocks get markers from day one.
- **Security files are always-on and stack-neutral.** `docs/SECURITY.md`, `.claude/settings.json`, `.claude/hooks/deps-guard.sh`, `.claude/agents/security-reviewer.md`, and `.claude/agents/tech-debt.md` ship unchanged for every language. Keep their wording stack-agnostic; the LLM-specific security rules live only in the fenced sections and the conditional `<ai-discipline>` block.
- **Line caps.** The ~100-line target / 200-line hard cap applies to **generated project files** -- everything under `templates/core/` and `templates/profiles/` (it becomes someone else's code). It does NOT apply to the generator/meta files: `init-project/SKILL.md`, `upgrade-project/SKILL.md`, and this repo's `AGENTS.md` are reference documents (interview + emission logic) and are necessarily longer. The core AGENTS.md constitution is a reference document like the SKILLs and may exceed the cap.
</editing-the-template>

<editing-the-skill>
`init-project/SKILL.md` has five phases (0 confirm, 1 install skills, 2 interview, 3 confirm plan, 4 write answers file + run render.py, 4.5 install deps, 5 verify). Phase 4 is executed by `render.py`, not by the agent; SKILL.md's Phase 4 is the answers-file schema plus a behavior table documenting what the renderer does. When editing:

- **Interview questions.** Numbered A1-A10 (product discovery) + B1-B12 (stack and opt-ins) today; B8 security profile, B12 Codex reviewer. Adding a question means adding it to (a) Phase 2 interview, (b) Phase 3 summary, (c) the placeholder table, (d) the Phase 4 answers-file schema (+ its example), and (e) `render.py` (validation + mapping/rule) if it affects the generated tree -- then regenerate the golden expected trees.
- **Conditional emission.** Every conditional rule is implemented in `render.py` and documented in the Phase 4 behavior table. No hidden conditionals, and no rule that exists only in prose -- if the renderer does not implement it, it does not happen.
- **Language profiles.** A profile is a YAML block in `<language-profiles>` (the human reference) PLUS `templates/profiles/<lang>/profile.json` (the renderer's machine-readable copy -- keep the two in sync; `golden_test.py` cross-checks the load-bearing scalars) PLUS the profile folder's actual files. B1 picks one. Python, TypeScript, Go, and Rust are complete; "Other" is not built. See `<adding-a-language-profile>`.
- **Verification.** Phase 5 checks core files with `test -f`, then confirms the profile landed, then runs `{{QA_COMMAND}}` green. If you add a new always-on file under `templates/core/`, add it to the core check.
</editing-the-skill>

<editing-the-upgrade-skill>
`upgrade-project/SKILL.md` reconciles an existing project against a fresh copy of `templates/core/` plus the project's own `templates/profiles/<lang>/`, so it is mostly self-maintaining: a **new always-on, placeholder-free file** you add to `core/` is picked up automatically (it is just "absent in the project -> copy verbatim"). You only need to touch the upgrade skill when a template change is one of these:

- **A new file with tooling/language placeholders** the upgrade cannot resolve from a recovered project context -> add a Phase 3-A special case (substitute what is recoverable, or report it for manual addition; never half-write a `{{...}}`).
- **A new `AGENTS.md` rule block** that should be grafted into existing projects -> it is covered by the generic "insert blocks present in the template but absent in the project" rule, but if it needs special placement or a conditional, note it in Phase 3-B.
- **A toolchain change** (new markers, deps, a split command, a CI job) -> add it to the Phase 3-C language-gated tooling delta.

When you ship a backport that changes the generated structure, bump `VERSION` (semver: breaking-to-old-projects = major, additive = minor). The version is informational for the upgrade report, not load-bearing -- the upgrade reconciles by capability detection, not by version diffing.
</editing-the-upgrade-skill>

<testing-changes>
Root CI (`.github/workflows/ci.yml`) tests every push -- it renders each profile (no leftover placeholders), re-renders the golden fixtures and compares them byte-for-byte against the committed expected trees, runs each profile's quality gate on the merged tree, and exercises the deps-guard. For most template changes the fast local loop is the renderer itself:

```bash
# Render any fixture (or your own answers file) and inspect the tree:
python3 init-project/render.py \
  --answers .github/fixtures/golden/python-ai-full.json \
  --core init-project/templates/core \
  --profile init-project/templates/profiles/python \
  --out /tmp/render-check
# Verify determinism against the committed expected trees:
python3 .github/scripts/golden_test.py
# After an INTENTIONAL template change, regenerate + commit the expected trees:
python3 .github/scripts/golden_test.py --update
```

Beyond that, the way to fully validate an end-to-end change (bootstrap + interview + deps) is to bootstrap a throwaway project and inspect what landed.

```bash
# In an empty directory outside this repo. The published one-liner is pinned to a
# release tag; to test UNRELEASED changes, override the ref with BRANCH=<branch>
# (here, main) so install.sh fetches the skill from that branch instead of the tag.
mkdir /tmp/template-smoke && cd /tmp/template-smoke && git init
BRANCH=main bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/main/bootstrap/install.sh)
# Open Claude Code, run /init-project, walk through the interview.
# Inspect the generated tree. Confirm:
#   - all placeholders are substituted (no leftover {{...}} in committed files)
#   - opt-in files are present or absent per your answers
#   - AGENTS.md has the expected blocks
#   - the QA gate passes on first run
```

For changes that don't need a full bootstrap (rewording rules, fixing typos, updating docs), inspecting the file in-place is enough.

Smoke output directories (e.g. `/tmp/forgeworks-smoke`) are scratch space and can be deleted at any time.
</testing-changes>

<adding-a-language-profile>
A complete profile is a YAML block PLUS a folder, both meeting the same readiness contract as Python/TypeScript/Go/Rust:

1. Create `init-project/templates/profiles/<lang>/` with: the manifest, toolchain config, a **verify-only** `qa` runner + a separate `fix` runner + a separate `e2e` runner (as shell scripts or package scripts), a **green-on-first-run scaffold** (a typed example module + a passing test), `.gitignore`, a dev container (hardened like the others), and -- only if the language idiomatically uses it -- a pre-commit config.
2. Add a YAML block to `init-project/SKILL.md` `<language-profiles>` with the same keys as Python's (qa_command, fix_command, e2e_command, ci_setup_steps, notes, ...) AND the matching `profile.json` in the profile folder (the renderer's input; `golden_test.py` cross-checks the two). Also extend `render.py`'s language enum and the answers-schema docs.
3. Add the language to B1's menu (mark it `[complete]` only once it passes the contract).
4. Add at least one golden fixture for the language and commit its expected tree (`golden_test.py --update`).
5. Bootstrap a throwaway project in that language and confirm `qa` is **green on the first run**.

`templates/core/` serves every language unchanged; everything language-specific lives in the profile folder, so nothing leaks across languages.
</adding-a-language-profile>

<conventions>
- **Boring tech beats clever tech.** Plain bash in `install.sh`, plain markdown for SKILL.md, plain string `.replace` for placeholder substitution. No template engines.
- **Plain English in docs and rule text.** Read every block aloud. If it does not survive being spoken, rewrite it.
- **Commit messages.** Conventional Commits style (`feat(template):`, `refactor(skill):`, `docs(readme):`). No Co-Authored-By trailer.
- **PRs vs direct commits.** Trivial changes (typos, doc edits) can go straight to `main`. Anything that touches `SKILL.md` Phase 4, `templates/core/AGENTS.md` rule blocks, or the bootstrap script goes via a PR for a second pass.
</conventions>

<release-process>
The published bootstrap one-liner is pinned to a **versioned release tag** so a project set up today gets the same template files tomorrow, even as `main` moves (runtime inputs like npm/degit/Context7 aren't fully reproducible yet — see `docs/ROADMAP.md`). `main` is for development; releases are tags.

When you ship a change that affects the generated structure, cut a release:

1. Bump `VERSION` (semver: breaking-for-old-projects = major, additive = minor).
2. Update the pinned `vX.Y.Z` ref everywhere it appears: the `REF` default in `bootstrap/install.sh`, the reconcile ref + target version in `upgrade-project/SKILL.md`, the `TEMPLATE_VERSION` stamp fallback in `init-project/render.py`, and the documented one-liners in `README.md` and `docs/how-to-use.md`.
3. Regenerate the golden expected trees (`python3 .github/scripts/golden_test.py --update`) -- the version stamp is part of the rendered bytes -- and commit them with the bump.
4. Merge to `main` (PR per `<conventions>`), then tag the merge commit and push it: `git tag vX.Y.Z && git push origin vX.Y.Z`.

To test unreleased changes, override the pin with `BRANCH=main` (see `<testing-changes>`). Still-open supply-chain hardening (review finding #8, deferred): pin GitHub Actions to commit SHAs, pin the Context7 MCP package to a version, and verify the `uv` installer by checksum.
</release-process>

<self-improvement>
**Run this after every real project, not just when something feels broken.** The end of a project is the trigger: review what went wrong and right, pull the project's `gotchas.md` / reviewer notes and any written feedback, and backport the generic lessons here so the next project starts with them baked in. This is the whole point of the template.

The pattern proven so far:
- First real project: product vision, style references, vertical-slice backlog, starting-a-slice habits, AI-discipline gating, opt-in memos, opt-in gotchas seed, opt-in mem0.
- A second project plus a security session: deeper planning (`<planning-discipline>` + grill-me), the full test pyramid with e2e at spec time, always-on security (`<security-discipline>`, `docs/SECURITY.md`, the deps-guard hook, `@security-reviewer`), bounded DRY, the full-picture implementer check, the Codex reviewer opt-in, and the `@tech-debt` sweep. Plus generic lessons mined from that project's `gotchas.md`: always set a subagent's model explicitly, parallel subagents contend on the `.git/index`, handle external I/O at one boundary (retry + degrade), validate inputs against a strict format allowlist (a real Codex-found gate bypass), and key LLM-node fakes off rendered state not call ordinal.

When backporting:
1. Confirm the lesson is truly generic (would apply to a TypeScript CLI, a Rust library, a Python web app, equally). Stack-specific bits go to language profiles or conditional/fenced content, never the always-on core.
2. Decide whether it belongs in `templates/core/AGENTS.md` (always-on), a conditional block (sometimes), or an opt-in (often-off).
3. If it adds an opt-in: add the wizard question, the placeholder, and the Phase 4 rule together. Never one without the others.
4. Validate by bootstrapping a throwaway project (see `<testing-changes>`), not by reading the diff. Land on a branch + PR.
</self-improvement>
