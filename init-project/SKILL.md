---
name: init-project
description: Bootstrap a new project through a short conversation (at most 5 questions; the agent infers the rest and states its defaults) that ends in an owner-approved one-page PRD, then renders the project deterministically -- AGENTS.md, the iteration/security-review/tech-debt skills, the reviewer and utility subagents with hooks, docs/ (PRD, machine-checked feature list, threat model, gotchas), CI, and the chosen language's toolchain with a green-on-first-run scaffold. Use whenever a project is uninitialized (no docs/features.json or .claude/agents/), when the user says "init", "bootstrap", "set up this project", "/init-project", or describes starting a new project. Pairs with the upstream `tdd` and `grill-me` skills from mattpocock/skills.
---

# init-project

Bootstraps a new project with a structured, agent-driven workflow. The
template's contents are stack-agnostic; every language and tooling choice is
made in this interview and substituted by the renderer. Reference material
lives next to this file and is read only when needed:

- `reference/renderer-rules.md` -- what `render.py` does with the answers.
- `reference/placeholders.md` -- every `{{PLACEHOLDER}}` and its source.
- `reference/language-profiles.md` -- the per-language toolchain reference.

## When this skill runs

The directory is empty or holds only a bootstrap `AGENTS.md`, and the user
asks to bootstrap, init, or set up the project.

## What it produces

A generated project is `templates/core/` (language-free) plus exactly one
`templates/profiles/<language>/`. The result: `AGENTS.md` (with `CLAUDE.md`
symlinked, for a Claude Code roster), `.claude/` (the `iteration`,
`security-review`, and `tech-debt` skills; the `reviewer` and `utility`
subagents; the quality-gate, deps-guard, and tree-claim hooks), `.mcp.json`
(Context7), `.github/` (CI with the quality gate, e2e, feature-check,
docs-budget, checkpoint-budget, resume-check, dup-check, and test-tamper
jobs, plus a PR template), `docs/` (PRD, `features.json` and its
`BACKLOG.md` view, SECURITY, language-standards, documentation, gotchas,
writing, plans/, probes/, agents; `design/` for frontend projects),
`scripts/` (`feature.py`, `resume.py`, `features_check.py`, `dup_check.py`,
`tamper_check.py`, `prune.py`, `backlog.py`, `factory_doctor.sh`,
`land.sh`, `skills_doctor.py`), `README.md`, `.env.example`,
`.worktreeinclude` (Claude Code roster), an optional
`.devcontainer/`, and the language's manifest, runners (`qa`, `fix`, `e2e`),
and green scaffold.

---

## Phase 0: Confirm intent

Ask: "I'm going to bootstrap this project. I'll ask a few questions about
scope and stack, then generate the structure. Continue?" Wait for a yes.

## Phase 1: Install the two upstream skills

```bash
npx skills@latest add mattpocock/skills
```

Pick `tdd` and `grill-me`. They are required: `grill-me` drives this
interview and every feature's GRILL step; `tdd` drives RED/GREEN. If the
user refuses, stop and explain that the loop cannot run without them.

**One copy per process skill.** This install is the only source of `tdd` and
`grill-me`. Ask which packs are enabled (`/plugin`); the `superpowers`
plugin (which also injects a SessionStart hook into every session) and the
`mattpocock-skills` plugin overlap and get disabled first. A field project
lost a week to three TDD skills racing. Phase 5 runs `scripts/skills_doctor.py`
to confirm.

## Phase 2: The conversation (at most 5 questions)

Run `grill-me` to drive it; if unavailable, mirror its style: probe
assumptions, surface trade-offs, ask the follow-up. Collect answers into
`docs/_init-answers.json` as you go (schema in Phase 4). Rule zero: nothing
this conversation can elicit ships as a TODO. Vague answer? Grill it: "How
would you verify that?", "What breaks first?", "Give me a real example input
and output."

Open with one prompt: "Describe the product you want -- what it does, for
whom, and anything you already know you want technically." Infer everything
possible, then ask only what is missing, one at a time, with choices where
they exist:

1. **What and for whom**, if the description left either unclear.
2. **Language**, if not inferable: Python / TypeScript / Go / Rust ("Other"
   is not built).
3. **Frontend?** Infer when obvious. If yes, one follow-up: "Name a product
   whose look you like, and one you hate" (feeds the design tokens and
   anti-reference). Go and Rust ship no starter `tokens.css`; say so.
4. **Security-sensitive?** "Will this hold real user data, payments, auth,
   take input from strangers, or send data out to external systems?" Shapes
   the SECURITY.md defaults and answers `acts_outward` directly.
5. **Which agents drive.** Probe first: `command -v codex`, `cursor`,
   `agy || antigravity`, `opencode`, `gemini`, plus any the user names.
   Claude Code counts as installed when this interview runs inside it.
   Options: claude-code / codex / antigravity / cursor / opencode / other
   (multi-select; default `claude-code`; a selected-but-not-installed agent
   is `"status": "planned"`). Without `claude-code`, warn that the
   Claude-specific enforcement (subagents, hooks, settings, the `CLAUDE.md`
   symlink) is not generated; `.claude/skills/` still ships as plain
   procedures.

Everything else takes the documented default: devcontainer yes,
explanations no, gotchas seed yes, mem0 no, codex reviewer only when codex
is in the roster. Say which defaults applied.

Derive and confirm: project name/slug, goal, primary user, core problem,
core journey, surfaces (screens/pages; empty for API/CLI), in-scope list,
non-goals, success metrics, differentiator, current alternative -- these
fill `docs/PRD.md`. Derive the factory **weight** (never a sixth question):
`lite` for a solo tool with no strangers' data, money, or outward writes;
`full` otherwise. Close by showing the drafted one-page PRD and a five-line
summary (language and product type, frontend, security-sensitive, weight,
agents, defaults applied) and getting an explicit OK. The PRD is
owner-approved before anything renders.

## Phase 3: Confirm the plan

Apply any last corrections from the end of Phase 2, state the rough file
count, and move on. Without an explicit OK, stay in Phase 2.

## Phase 4: Render (deterministic)

`render.py` generates everything; your job is a correct answers file. Same
answers, same bytes, proven by the template repo's golden fixtures.

**Step 1: write `docs/_init-answers.json`** in exactly this schema. All
top-level keys and every key inside the four object sections are required;
yes/no fields are the literal strings `"yes"`/`"no"`; multi-line values use
`\n`. Values below are abbreviated:

```json
{
  "schema": 1,
  "date": "2026-07-12",
  "weight": "full",
  "agents": [{"name": "claude-code", "status": "installed"}],
  "project": {
    "name": "Recipe Radar",
    "slug": "recipe-radar",
    "goal": "Turn a photo of a fridge into three cookable dinner suggestions.",
    "primary_user": "A busy home cook ...",
    "core_problem": "...",
    "core_journey": "1. ...\n2. ...\n3. ...",
    "success_measure": "...",
    "success_metrics": "- metric -- target",
    "riskiest_assumption": "...",
    "req_ac_list": "- [ ] **REQ-AC1:** ...\n- [ ] **REQ-AC2:** ...",
    "non_goals": "- ...",
    "other_users": "- none identified yet",
    "constraint_time": "...",
    "constraint_cost": "...",
    "constraint_data": "...",
    "first_milestone": "2026-08-09 (or: none set)",
    "deployment_target": "...",
    "scale_expectations": "...",
    "integrations": "- none",
    "in_scope_list": "- ...",
    "pain_point": "...",
    "product_category": "...",
    "current_alternative": "...",
    "key_benefit": "...",
    "key_differentiator": "...",
    "positive_reference": {"ref": "simonw/datasette", "location": "https://github.com/simonw/datasette"},
    "negative_reference": null,
    "surfaces": ["Fridge photo upload", "Ingredient review", "Recipe results"]
  },
  "stack": {
    "language": "python",
    "has_frontend": "yes-minimal",
    "backend_framework": "FastAPI",
    "ai_features": ["rag", "agents"],
    "vector_db": "Chroma",
    "llm_provider": "OpenAI",
    "embeddings_model": "text-embedding-3-small",
    "database": "SQLite",
    "uses_devcontainer": "yes"
  },
  "security": {
    "reads_untrusted": "yes",
    "holds_private_data": "yes",
    "acts_outward": "no"
  },
  "opt_ins": {
    "explanations": "no",
    "seed_gotchas": "yes",
    "mem0": "no",
    "codex_reviewer": "no"
  },
  "features": [
    {
      "id": "F001",
      "title": "Extract an editable ingredient list from a fridge photo",
      "intent": "Uploading a clear fridge photo yields an editable ingredient list within 15 seconds.",
      "serves": "journey step 2: the app extracts an ingredient list and shows it for one-tap correction",
      "acceptance": ["Uploading a clear fridge photo produces an editable ingredient list within 15 seconds."],
      "tests": [],
      "status": "todo",
      "tier": "feature",
      "surface": "Ingredient review"
    }
  ],
  "design": {
    "references": "- datasette.io -- plain, content-first layout that gets out of the way",
    "tone": "warm, uncluttered, mobile-first",
    "anti_reference": "cluttered recipe blogs: ad blocks, autoplay video, ingredient list buried under a life story"
  }
}
```

Every field is required even though Phase 2 asks at most 5 questions;
inference is the interviewer's job. Fields Phase 2 does not name (riskiest
assumption, constraints, milestone, deployment, scale, integrations, other
users, the codebase-shape reference) still get a value derived from the
conversation, or `TODO(interview-skipped)` when the owner explicitly declined.

Rules the renderer enforces (it fails closed with a precise message):

- `slug`: lowercase ASCII words joined by hyphens; it becomes the package identifier.
- `language`: `python` / `typescript` / `go` / `rust`. `has_frontend`: `yes-spa` / `yes-minimal` / `no`. `ai_features`: a subset of `["rag", "agents", "evals", "streaming"]`, `[]` for none.
- `surfaces`: a list of strings (`[]` for an API/CLI product); a feature's `surface` names one of them or `"none"`.
- Free text lands verbatim in prose files and escaped in JSON/TOML, so any characters are fine except HTML comment markers and `{{UPPER_SNAKE}}`-shaped text. Fields that land in `AGENTS.md` (`goal`, `primary_user`, the style references) stay short: the rendered file has a size cap.
- No bare `TODO` in any answer; only `TODO(interview-skipped)`. `date` is today, ISO format.
- `vector_db`, `llm_provider`, `embeddings_model`, `database`, `backend_framework`: `none` when not applicable.
- `agents`: non-empty, no duplicates, names from the Phase 2 list, status `installed` or `planned`. `codex_reviewer: "yes"` requires `codex` in the roster.
- `features`: non-empty. Each entry: `id` (`F000`-`F999`, unique), `title`, `intent`, `serves` (a `docs/PRD.md` section; cannot name one? question the feature), `acceptance` (non-empty), `tests` (`[]` at bootstrap), `status` (`todo`), `tier` (`chore` or `feature`), `surface`. Derive 3-7 features from the core journey, user-visible journey first; acceptance criteria from the conversation feed each `acceptance` array.
- `design`: `references`, `tone`, `anti_reference` when `has_frontend` is not `"no"`; `null` otherwise.
- `weight`: `"lite"` or `"full"`. Lite runs the e2e job at release tags instead of every push and makes the dup gate advisory; every hard rule is identical in both.

**Step 2: run the renderer** from the project root:

```bash
python3 .claude/skills/init-project/render.py \
  --answers docs/_init-answers.json \
  --core .claude/skills/init-project/templates/core \
  --profile .claude/skills/init-project/templates/profiles/<language> \
  --out .
```

If it fails, fix the answers file (or report the template bug) and re-run.
Never hand-patch the generated tree around a renderer error and never
substitute a placeholder by hand. What the renderer does with each answer is
in `reference/renderer-rules.md`.

## Phase 4.5: Install dependencies

The one step that stays with the agent, because it runs package managers.
Append only the dependencies the answers call for (framework, database,
vector store, LLM SDK, `mem0ai` if opted in) with the profile's
`add_dep_command` (`DEPS_VETTED=1` in front for Python's `uv add`, so the
deps-guard hook lets a vetted install through). Choose the smallest set;
add nothing the project did not ask for.

Then, unless a dev container was chosen: run `{{INSTALL_COMMAND}}` and
smoke-test the toolchain (`uv run python -c "print('ok')"`, `node -e`,
`cargo --version`, `go version`). If the install fails, leave the scaffold
in place and report the failing dependency. With a dev container, append
the deps and skip the install; they install inside the container.

## Phase 5: Verify and report

Core files, every project:

```bash
test -f AGENTS.md && test -f README.md && test -f .env.example && \
test -f .mcp.json && test -f .claude/.template-version && \
test -f .github/workflows/qa.yml && test -f .github/pull_request_template.md && \
test -f docs/PRD.md && test -f docs/features.json && test -f docs/BACKLOG.md && \
test -f docs/SECURITY.md && test -f docs/language-standards.md && \
test -f docs/writing.md && test -f docs/plans/README.md && \
test -f docs/agents.md && test -f docs/agents.json && \
python3 scripts/features_check.py && python3 scripts/dup_check.py && \
python3 scripts/resume.py --check && python3 scripts/prune.py --check && \
test -f scripts/feature.py && test -f scripts/tamper_check.py && \
test -f scripts/factory_doctor.sh && test -f scripts/skills_doctor.py && \
test -f .claude/skills/iteration/SKILL.md && \
test -f .claude/skills/iteration/reference/dispatch.md && \
test -f .claude/skills/security-review/SKILL.md && \
test -f .claude/skills/tech-debt/SKILL.md
```

Run `python3 scripts/skills_doctor.py` and show its output. A `FAIL` line is
a duplicated skill name or an always-on SessionStart plugin; the fix is the
owner's (`/plugin`). The first line of the final report is that FAIL, before
any "done".

When `claude-code` is in the roster:

```bash
test -L CLAUDE.md && test -f .claude/agents/reviewer.md && \
test -f .claude/agents/utility.md && test -f .claude/settings.json && \
test -f .claude/hooks/deps-guard.sh && test -f .claude/hooks/tree-claim.sh && \
test -f .worktreeinclude
```

Otherwise tell the user the Phase 1 upstream skills are inert for their
agents and safe to delete; the generated `.claude/skills/` procedures stay.

When the project has a frontend: `test -f docs/design/DESIGN.md`.

Then confirm the profile landed (its manifest and the green scaffold source
and test exist), and that no placeholder survived:

```bash
! grep -rn '{{[A-Z0-9_]*}}' . --include='*.md' --include='*.toml' --include='*.yml' \
  --include='*.yaml' --include='*.json' --include='*.sh' --include='*.py' \
  --include='*.ts' --include='*.go' --include='*.rs' --include='*.mod' \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=skills
```

Delete the renderer input: `rm docs/_init-answers.json`. Then run the quality
gate (`{{QA_COMMAND}}`, inside the dev container if one is used). Every
profile ships a green-on-first-run scaffold; a project that starts red is a
bug to fix before handing off.

Last, delete this skill: `rm -rf .claude/skills/init-project`. It is build
equipment, not project content; nothing in the project reads it, and a stale
copy fossilizes the generator. `/upgrade-project` installs its own skill
when the owner runs it.

Report:

> "Bootstrap complete. Next steps:
> 1. {{If dev container}}: reopen in the container, then `{{INSTALL_COMMAND}}`. {{Else}}: deps are installed and `{{QA_COMMAND}}` is green.
> 2. `git add . && git commit -m 'chore: bootstrap project'`, then push to enable CI.
> 3. Restart Claude Code so `.mcp.json` (Context7) registers.
> 4. Start the first feature: the `iteration` skill on the first `docs/features.json` entry."

If the repo has a GitHub remote and `gh` is available, offer (do not run
unasked) branch protection requiring the `qa`, `e2e`, and `features-check`
checks. Without it a red build can still be merged by pushing directly.

---

## Failure modes

- **The user cannot decide on a language.** Default to Python.
- **The user wants to skip the interview.** Minimum: name, one-sentence goal, the core flow, one acceptance criterion. Everything else takes the default or `TODO(interview-skipped)`.
- **Non-empty directory.** Refuse unless the user confirms after seeing what would be overwritten.
- **Skill installation fails (no npm/node).** Stop; `tdd` and `grill-me` are required.
- **Package manager missing.** Stop with the install link for `uv`, `npm`, `cargo`, or `go`.
- **Context7 fails to start after bootstrap.** Check `npx`; if broken, note it in `docs/gotchas.md` and let the user fix npx or remove the entry from `.mcp.json`.
