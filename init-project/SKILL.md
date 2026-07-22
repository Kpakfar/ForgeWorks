---
name: init-project
description: Bootstrap a new project with five focused subagents (test-spec-writer, implementer, code-reviewer, security-reviewer, tech-debt), a static+test quality-gate hook, a supply-chain guard hook, Context7 MCP, CI (fast gate plus an end-to-end job), PR template, pre-commit config, dev container, a threat-model doc, and structured documentation. Stack-agnostic at its core: language and tooling choices live in this skill's interview, not in the template files. Use this skill whenever a project is uninitialized (no docs/structure.txt or .claude/agents/), when the user says "init", "bootstrap", "set up this project", "/init-project", or describes wanting to start a new AI engineering project. Interviews the user deeply about scope, the heart of the project, security profile, and stack, then generates AGENTS.md, .claude/, .mcp.json, docs/, .github/, .devcontainer/, scripts/, and a manifest tailored to the chosen language. Pairs with the upstream `tdd` and `grill-me` skills from mattpocock/skills, installed during bootstrap.
---

# init-project

This skill bootstraps a new project with a structured, agent-driven workflow. The template's contents are stack-agnostic; all language and tooling choices are made through this skill's interview, then substituted into placeholders at generation time.

## When this skill runs

- The current directory is empty or contains only a bootstrap `AGENTS.md`.
- The user says: "bootstrap", "init", "set up the project", "/init-project", or similar.
- The user describes wanting to start a new project.

## What this skill produces

A fully structured project with:

- `AGENTS.md` and `CLAUDE.md` (symlinked): the constitution, stack-agnostic core
- `.claude/agents/`: five focused subagents (test-spec-writer, implementer, code-reviewer, security-reviewer, tech-debt)
- `.claude/hooks/quality-gate.sh`: deterministic static+test gate triggered by code-reviewer
- `.claude/hooks/deps-guard.sh` + `.claude/settings.json`: best-effort supply-chain guard (PreToolUse hook)
- `.mcp.json`: Context7 MCP server for live library docs
- `.github/workflows/qa.yml`: CI running the quality gate (fast) and a separate end-to-end job on pull requests and pushes to main
- `.github/pull_request_template.md`: short PR checklist
- `.pre-commit-config.yaml`: local pre-commit hooks (language-specific portion populated from your profile)
- `docs/`: living documentation (structure, requirements, language-standards, gotchas, backlog, SECURITY, current-task)
- `.devcontainer/`: portable development environment (if chosen)
- `README.md` + `.env.example`: project readme (commands, flow) and a documented, secret-free env template
- A minimal green scaffold for the chosen language (a placeholder module + a passing test) so the quality gate passes on the first run
- The chosen language's runners: a non-mutating quality gate (`qa`), a local auto-fix (`fix`), and a separate end-to-end runner (shell scripts for Python/Go, npm scripts for TypeScript)
- `{{MANIFEST_FILE}}`: dependency + tool config + bundled scripts entry
- A working venv / node_modules / equivalent via the chosen package manager (skipped if dev container is chosen; deps install inside the container instead)

The TDD methodology is provided by the upstream `tdd` skill from `mattpocock/skills`, installed during this skill's Phase 1. Three subagents pair with the loop (test-spec-writer, implementer, code-reviewer); two more run on a recurring cadence (security-reviewer, tech-debt). Main context drives; subagents are escape hatches for complex phases.

---

## Workflow

### Phase 0: Confirm intent

Before doing anything, confirm with the user:

> "I'm going to bootstrap this project. I'll ask you a few questions about scope and stack, then generate the full structure. Continue?"

Wait for explicit confirmation.

### Phase 1: Install supporting skills (REQUIRED)

The core loop uses **`mattpocock/skills`** -- specifically `tdd` and `grill-me`. This is a deliberate choice: in practice these gave a better experience than the broader `superpowers` pack, so use `mattpocock/skills` as the default and do not substitute another pack for the core loop.

**Always pull the latest.** Skill packs evolve; run the install (which resolves `@latest`) every bootstrap, even if some skills look already present, so the project starts on current versions:

```bash
npx skills@latest add mattpocock/skills
```

Required skills (must be installed): `tdd`, `grill-me`, `to-prd`, `caveman`, `write-a-skill`, `handoff`.

After the user picks them in the skills picker, verify `tdd` and `grill-me` are present before proceeding. `grill-me` is what powers the planning pass (Phase 2 and the per-slice `<planning-discipline>`); do not skip it. If the user refuses or skips, stop and explain why bootstrap cannot continue without `tdd` and `grill-me`.

### Phase 2: Interview

This is a planning interview, not a form. Do not be lazy here and do not just transcribe answers -- interrogate them. Run the `grill-me` skill (from mattpocock/skills) to drive it; if unavailable, mirror its style: probe assumptions, surface trade-offs, ask the follow-up.

Start from the **heart of the project**: the one flow that, if it works, makes the project worth building. Get that crisp before anything about stack or tooling. Ask the questions below one at a time (or in tight groups of 2-3 if obviously related), but treat A1-A2 as a real discovery, not a single line each.

**Be proactive about what's missing.** The complaint that drove this design is interviews that record what the user says and stop there. After the core questions, run one explicit "what haven't we talked about?" pass and name the gaps yourself: error and empty states, the unhappy path, auth and who can see what, scale, observability, the riskiest assumption. Tell the user what you think they have not considered. A good interview leaves the user thinking "I hadn't thought of that."

Collect answers as you go directly into `docs/_init-answers.json` -- the renderer input whose schema is defined in Phase 4 (it is deleted after Phase 5 verification).

The interview has two parts, in this order: **Part A -- product discovery** (the
project itself; this is where surprises are killed) and **Part B -- stack and
options** (machinery). Rule zero: **nothing this interview can elicit ships as a
TODO in the generated docs.** When an answer is vague, grill it: "How would you
verify that?", "What breaks first?", "Give me a real example input and output."

**Part A -- product discovery**

#### A1. Project name and one-sentence goal
- What's the project called?
- In one sentence, what does it do and for whom?

Probe: who is the *primary* user? If they list multiple, narrow to one for the MVP.

From the name, derive a **`{{PROJECT_SLUG}}`** for use in manifests / module paths: lowercase, ASCII, words joined by hyphens, no spaces or punctuation (e.g. "My Project!" -> `my-project`). The display `{{PROJECT_NAME}}` is for prose only; the slug is what goes into a package name, `package.json` name, or Go module path -- raw display names break TOML/JSON/`go.mod`. If the derived slug is empty or invalid, ask the user for one.

#### A2. The core problem, the heart, and the positioning
- What problem is this solving that existing tools don't solve well? Why now?
- **The heart:** describe the single most important user-visible flow end to end -- the one that, if it works, makes the whole thing worth building. This is what the first slices target.
- What does success look like concretely? How will you know the flow works (a metric, an example output, a user reaction)?
- What is the riskiest assumption -- the one thing that, if wrong, sinks the project? Plan to test it early.

Probe until these are concrete. If the answers are abstract, ask for a worked example (a real input and the output it should produce).

Also pin the positioning while you are here (these feed `docs/PRODUCT_VISION.md`
directly -- do not leave them for later): what CATEGORY is this product
(one noun phrase), what is the user's PAIN in one line, what is the CURRENT
ALTERNATIVE they use today, what is the KEY BENEFIT in one line, and what is the
KEY DIFFERENTIATOR versus that alternative? Phrase each so the assembled
positioning statement reads as ONE grammatical sentence: the pain must complete
"who ..." (e.g. "stares at a full fridge with no dinner idea"), the benefit must
complete "that ..." (e.g. "turns what you have into what you can cook").

#### A3. Acceptance criteria for the first iteration

Ask for 3-5 numbered, observable statements that, when all true, mean the MVP
works. These become `REQ-AC1..n` in `docs/requirements.md` -- the iteration
contract every slice cites. Probe each until it is verifiable by hand: "How
would you check this one?" Reject vague criteria ("it should be fast") and
help sharpen them ("p95 under 2s on 1k documents").

#### A4. Non-goals

What will this project deliberately NOT do in the first iteration? Get at least
two concrete non-goals. These render into `{{NON_GOALS}}` -- they are the main
defense against scope surprises.

#### A5. Constraints

- Time: deadline or cadence (sprint, hackathon, side project)? Derive the first
  milestone date if one exists.
- Cost: any budget, INCLUDING an LLM/API budget if AI features are likely?
- Data: corpus size, allowed sources, licensing constraints?

#### A6. Deployment target

Where does this run for its users -- local CLI, internal tool, public web app,
mobile, embedded? And where will it be hosted or deployed first (a laptop, a
VPS, a PaaS, on-prem)?

#### A7. Scale and performance expectations

Order of magnitude for the first iteration: how many users, requests, and how
much data? Any hard latency expectation on the core flow? "Just me, small" is a
fine answer -- but it must be recorded, not assumed.

#### A8. External systems and integrations

What existing systems, third-party APIs, or data sources must this talk to?
List each. Every one of these will need a reality probe (`docs/probes/`) before
any code builds on it -- say so now so it is not a surprise later.

#### A9. Other user segments

Besides the primary user (A1): who else might use this later? One line each;
they are recorded as deferred, not built.

#### A10. Style references

Every project drifts without a style anchor. Pick one positive reference for the agent to pattern-match.

- **Positive reference (required):** a concrete artifact -- public repo URL, deployed product, folder on disk, design system, or screenshot directory -- that this project should resemble in shape and idioms. Ask: "Is there a project you have looked at and thought 'I want this codebase to feel like that one'?"
- **Negative reference (optional):** a concrete artifact whose shape you want to avoid.

Save the location (URL or path) for each. If the user has nothing for the positive reference, suggest picking one before the first real slice; leave a TBD placeholder for now.

**Part B -- stack and options**

#### B1. Language

```
  1) Python       (uv, ruff, mypy, pytest)            [complete]
  2) TypeScript   (npm, eslint, prettier, tsc, vitest) [complete]
  3) Go           (go mod, golangci-lint, go test)     [complete]
  4) Rust         (cargo, clippy, rustfmt)             [complete]
  5) Other        (manual setup)                       [not yet -- experimental]
```

Python, TypeScript, Go, and Rust each have a **complete profile** (`templates/profiles/<lang>/`) with a working toolchain and a green-on-first-run scaffold -- pick any of them and the quality gate passes immediately. "Other" is not yet built; see "Experimental languages" below before generating one.

#### B2. Frontend

- Will this project have a frontend in this sprint?
  - **yes-spa**: full SPA (React, Next, Vue, etc.)
  - **yes-minimal**: Streamlit, Gradio, plain HTML
  - **no**: API-only or notebook-only

#### B3. Backend framework (if applicable)

Offer the menu for the chosen language; do not improvise:

- Python: 1) FastAPI  2) Flask  3) Streamlit/Gradio only  4) none (CLI/library)
- TypeScript: 1) Next.js  2) Express  3) Fastify  4) none (CLI/library)
- Go: 1) stdlib net/http  2) chi  3) gin  4) none (CLI/library)
- Rust: 1) axum  2) actix-web  3) none (CLI/library)

#### B4. AI features

- Will this project use:
  - RAG (retrieval-augmented generation)? Vector DB choice: pgvector / Chroma / Pinecone / Qdrant
  - LLM agents (multi-step reasoning)?
  - Evals (LLM output testing)?
  - Streaming responses?

Record answers for `requirements.md` and to scaffold relevant test categories.

#### B5. LLM provider and embeddings model
- Provider: OpenAI / Anthropic / Google / Together / OpenRouter / local (Ollama / LM Studio) / multiple via a router
- Embeddings model: name (e.g. `text-embedding-3-small`, `bge-large-en-v1.5`)

#### B6. Database / persistence (if applicable)
- None / SQLite / Postgres / DuckDB / KV store / file-based

#### B7. Dev container?
- Do you want to run this project in a dev container? (yes / no)
- If yes, base image defaults to the language profile's recommendation.

Trade-offs:
- **Yes:** isolated environment, reproducible across machines, matches production, and confines what an agent with broad permissions can touch on the host filesystem.
- **No:** simpler setup, no Docker required, easier if you're on a constrained machine or just prototyping.

#### B8. Security profile

Three quick yes/no questions that set the project's threat model (these seed `docs/SECURITY.md` and `docs/requirements.md`):

- Does it **read untrusted content** (web pages, user uploads, third-party API or tool results, inbound messages)?
- Does it **hold private data** (user records, secrets, anything not public)?
- Does it **act on the outside world** (send messages/email, write to external systems, make purchases, run tools with side effects)?

Any "yes" means the security blocks and red-team tests matter. All three "yes" on a single LLM agent is the **lethal trifecta** -- flag it explicitly and note in `docs/SECURITY.md` how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human).

#### B9. Per-slice explanation memos (opt-in)

> "Do you want a plain-English memo generated when each slice ships? Useful for learning projects, handoffs, and codebases that need to be defended in review. Skip if you do not need the trail."

Yes / No. Default: No.

#### B10. Seed `gotchas.md` with three starter entries (opt-in)

> "Do you want `docs/gotchas.md` pre-seeded with three generic lessons (patch the cause not the symptom; trust artifacts not summaries; handle external I/O at one boundary)? Demonstrates the file's purpose and shape."

Yes / No. Default: Yes.

#### B11. Pre-wire mem0 for persistent memory (opt-in)

> "Does this project need persistent memory across sessions (user preferences, agent state, conversation history)? If yes, mem0 is added as a dependency in local library mode."

Yes / No. Default: No. Link: https://github.com/mem0ai/mem0

#### B12. Codex as a second-opinion reviewer (opt-in)

Ask ONLY if `codex` is in the B13 roster (B13 is asked first); otherwise record `"no"` silently.

> "Do you have the Codex CLI available? If so, the code-reviewer can run an independent Codex pass for a second perspective on important changes."

Yes / No. Default: No. If yes, the generated `code-reviewer` agent includes a step to invoke Codex and reconcile its findings.

#### B13. Agent roster -- which agentic coders drive this project

Asked BEFORE B12 in the conversation (B12 only applies when `codex` is in the
roster; the numbering is historical).

First PROBE, do not guess: check which agent CLIs are installed
(`command -v codex`, `command -v cursor`, `command -v agy || command -v antigravity`,
plus any the user names). Claude Code counts as installed when this interview
runs inside it. Then ask:

> "Which agentic coders will drive this project? (multi-select)
>  - claude-code {installed?} -- full enforcement: subagents, hooks, /select-agents
>  - codex {installed?} -- rules + dispatch target (codex exec)
>  - antigravity {installed?} -- rules + dispatch target
>  - cursor {installed?} -- rules, interactive second opinion
>  - other -- rules only; roles assigned manually"

Default: `claude-code` alone. At least one required. A selected agent that is
not installed is recorded with `"status": "planned"`. The roster lands in the
answers file as the top-level `agents` list and, after render, lives on as the
RUNTIME config `docs/agents.json` (+ the `docs/agents.md` matrix) -- changeable
any time via `/select-agents`, never frozen at bootstrap.

If `claude-code` is NOT selected: warn that the enforcement stack (subagents,
hooks, settings, skills) will not be generated, and that the bootstrap-installed
files under `.claude/skills/` are inert and safe to delete after Phase 5.

### Phase 3: Confirm the plan -- show the filled docs, not a settings list

Render (in memory) the discovery content that will land in the docs and show it
to the user BEFORE generating -- surprises must surface here, not after:

> "Here is what your docs will say. Correct anything that reads wrong.
>
> **Positioning:** For {primary user} who {pain}, {name} is a {category} that
> {key benefit}. Unlike {alternative}, we {differentiator}.
> **Core flow:** {numbered steps}
> **Acceptance criteria:** {REQ-AC1..n}
> **Non-goals:** {list}   **Constraints:** {time / cost / data}
> **Deployment:** {target}   **Scale:** {expectations}
> **Integrations (each will need a reality probe):** {list}
> **Success metric:** {metric}   **Riskiest assumption:** {assumption}
>
> Stack: {language}, frontend {answer}, backend {answer}, DB {answer},
> AI {list or none}, LLM {provider or none}, dev container {yes/no},
> security profile {three answers}{trifecta warning if all three},
> opt-ins: memos {y/n}, gotchas seed {y/n}, mem0 {y/n}, Codex {y/n}; agents: {roster with installed/planned marks}.
>
> This will create approximately {N} files. Proceed?"

Read the assembled positioning sentence aloud; if it does not survive being spoken, fix the phrasing with the user before generating.

Wait for confirmation and apply corrections before Phase 4.

### Phase 4: Generate the scaffold (deterministic render)

Generation is executed by the bundled renderer, **`render.py`**, never by hand.
Your whole job in this phase is to produce a correct answers file; the renderer
guarantees that the same answers always produce the same bytes (the template
repo's CI proves this against committed golden fixtures).

A generated project is **the universal core plus exactly one language profile**
-- nothing from any other language is ever copied in. Three source folders feed
the renderer:

- `templates/core/` -- language-free files every project gets (AGENTS.md, docs/, `.mcp.json`, the CI workflow shape, PR template, README, .env.example, `.claude/`).
- `templates/profiles/<language>/` -- the chosen language's files (manifest, toolchain config, `scripts/` or package scripts, the green scaffold, `.gitignore`, dev container, and -- Python only -- a pre-commit config), plus `profile.json`: the machine-readable toolchain values the renderer substitutes. `profile.json` is renderer input only and never lands in the generated project. Keep it in sync with the YAML block in `<language-profiles>` below (CI cross-checks the load-bearing values).
- `templates/conditional/` -- the canonical texts of the conditional blocks: `ai-discipline.md`, `memory-block.md`, `memory-doc-line.md`, `codex-review-step.md`, `codex-roster-note.md`, `gotchas-seed.md`, and the per-agent roster snippets under `agents/`. Edit them THERE; this file only points at them.

**Step 1 -- write the answers file** at `docs/_init-answers.json`, exactly in
this schema. All four sections and every key are required; yes/no fields are the
literal strings `"yes"`/`"no"`; multi-line values use `\n`. Example (values
abbreviated -- yours carry the real interview content):

```json
{
  "schema": 1,
  "date": "2026-07-12",
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
    "negative_reference": null
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
  }
}
```

Field rules the renderer enforces (it fails closed with a precise message):

- `slug`: lowercase ASCII words joined by hyphens (`my-project`) -- it becomes the package/module identifier.
- `language`: one of `python` / `typescript` / `go` / `rust`. `has_frontend`: `yes-spa` / `yes-minimal` / `no`. `ai_features`: any subset of `["rag", "agents", "evals", "streaming"]`; `[]` means no AI features.
- Free-text answers land verbatim in prose files (and escaped in JSON/TOML), so any characters are fine EXCEPT HTML comment markers (`<!--`/`-->`) and `{{UPPER_SNAKE}}`-shaped text, which the renderer rejects.
- Rule zero still holds: no bare `TODO` in any answer. The only allowed form is `TODO(interview-skipped)` when the user explicitly refused a question. `date` is today, ISO format.
- `vector_db`, `llm_provider`, `embeddings_model`, `database`, `backend_framework`: write `none` (or `none (CLI/library)` for the framework) when not applicable.
- `agents` (top-level): non-empty list of `{"name", "status"}`; `name` one of `claude-code` / `codex` / `antigravity` / `cursor` / `other` (no duplicates), `status` `installed` or `planned`. `codex_reviewer: "yes"` requires `codex` in the roster.

**Step 2 -- run the renderer** from the project root:

```bash
python3 .claude/skills/init-project/render.py \
  --answers docs/_init-answers.json \
  --core .claude/skills/init-project/templates/core \
  --profile .claude/skills/init-project/templates/profiles/<language> \
  --out .
```

If it fails, fix the answers file (or report the template bug) and re-run. Do
NOT hand-patch the generated tree around a renderer error and do NOT perform
any substitution manually -- that reintroduces exactly the nondeterminism this
renderer removed.

**What the renderer does.** Documentation of behavior, not manual steps -- the
canonical implementation is `render.py`, locked byte-for-byte by the golden
fixtures in the template repo CI:

| # | Rule (from the answers) |
|---|---|
| 1 | Substitutes every placeholder in the tables below (core + the chosen profile only), re-indenting multi-line values to the placeholder's own column so YAML stays valid. |
| 2 | Escapes free-text answers per target format: JSON-escaped in `.json`, TOML-escaped in `.toml`, verbatim in Markdown/text -- hostile quotes/newlines/braces land as text, never as structure. Free text in any other file type is a hard error. |
| 3 | AI features selected -> renders `{{AI_DISCIPLINE_BLOCK}}` from `templates/conditional/ai-discipline.md`; none -> empty. |
| 4 | AI fences: AI on -> strips only the marker lines and keeps the content; AI off -> deletes the whole fenced blocks in `docs/SECURITY.md`, `docs/requirements.md`, `.claude/agents/implementer.md`, `.claude/agents/code-reviewer.md`. |
| 5 | Style references (A10): renders the positive/negative reference lines, or the "no positive reference yet" comment / empty string. |
| 6 | B9 `explanations: no` -> `docs/explanations/` is not generated. |
| 7 | B10 `seed_gotchas: yes` -> inserts the three starter entries from `templates/conditional/gotchas-seed.md` into `docs/gotchas.md`. |
| 8 | B11 `mem0: yes` -> keeps `docs/memory.md`, renders the memory doc line, inserts the `<memory>` block (from `templates/conditional/memory-block.md`) between `<library-docs>` and `<tools>`; `no` -> none of those. The `mem0ai` dependency itself is added in Phase 4.5. |
| 9 | B12 `codex_reviewer: yes` -> renders `{{CODEX_REVIEW_STEP}}` and `{{CODEX_ROSTER_NOTE}}` from `templates/conditional/codex-*.md`; `no` -> both empty. |
| 10 | B8: seeds the security-profile line into `docs/SECURITY.md`; if all three answers are `yes` AND AI features are on, writes the lethal-trifecta-PRESENT note into `docs/SECURITY.md` and `docs/requirements.md`. |
| 11 | B7 `uses_devcontainer: no` -> `.devcontainer/` is not generated. |
| 12 | B2 + profile: renders `{{E2E_BROWSER_INSTALL_STEP}}` as the browser-install step (UI project with a profile `e2e_browser_install`) or the "no browser needed" comment. |
| 13 | Renames profile manifests shipped with an `.example` suffix (`pyproject.toml.example` -> `pyproject.toml`). Core files are never renamed (`.env.example` stays). |
| 14 | Creates the `CLAUDE.md` -> `AGENTS.md` symlink (a one-line pointer file where symlinks are unavailable), `chmod +x` on `.claude/hooks/*.sh` and `scripts/*.sh`, and stamps `.claude/.template-version` (with this release's version) if the bootstrap `install.sh` did not already write it. |
| 15 | Fails closed if any `{{...}}` placeholder survives anywhere in the output. |
| 16 | B13: when `claude-code` is NOT in `agents`, the entire `.claude/` tree (agents, hooks, settings, skills) and the `CLAUDE.md` symlink are not generated; the `.claude/.template-version` stamp is always written. |
| 17 | B13: renders `{{AGENT_MATRIX}}` in `docs/agents.md` from `templates/conditional/agents/<name>.md` (planned agents get a status note) and writes the machine-readable roster `docs/agents.json` (name, status, offload roles). |

Keep `docs/_init-answers.json` until Phase 5 verification passes, then delete it
(`rm docs/_init-answers.json`) -- its content lives on in the rendered docs.

### Phase 4.5: Install dependencies

Dependency work is the one part of generation that stays with the agent: it
runs environment-dependent package-manager commands, so it cannot be a
deterministic file render. Two steps.

**First, capability dependencies (B3-B6).** The rendered manifest ships a
minimal core only; append ONLY the dependencies the answers call for, using the
chosen profile's `add_dep_command` (prefix Python's `uv add` with
`DEPS_VETTED=1` so the deps-guard hook lets a vetted install through). Map
intent to packages, per language:

- **Python** -- FastAPI: `fastapi`, `uvicorn[standard]`; Flask: `flask`; Streamlit/Gradio: `streamlit`/`gradio`; Postgres: `sqlalchemy`, `alembic`, `psycopg[binary]`; SQLite/DuckDB: `sqlalchemy`/`duckdb`; vectors: `pgvector`/`chromadb`/`pinecone-client`/`qdrant-client`; LLM: `openai` (also OpenRouter)/`anthropic`/`google-genai`; `httpx` for outbound HTTP.
- **TypeScript** -- API: `express` or `fastify` (+ `@types/*`); Postgres: `pg`+`@types/pg` or `drizzle-orm`; vectors: `chromadb`/`@pinecone-database/pinecone`/`@qdrant/js-client-rest`; LLM: `openai`/`@anthropic-ai/sdk`/`@google/genai`; config validation: `zod`. Frontend frameworks (React/Next/Vue) per the user's choice.
- **Go** -- HTTP: stdlib `net/http` (no dep) or `chi`/`gin`; Postgres: `github.com/jackc/pgx/v5`; LLM: the provider's official Go SDK or `net/http`. Add via `go get`.
- **Rust** -- HTTP server: `axum` or `actix-web` (+ `tokio`); Postgres: `sqlx`; LLM: the provider's official Rust SDK or `reqwest`. Add via `cargo add`.

Choose the smallest set that covers the answers; do not add a database/vector/LLM dep the project did not ask for. If B11 chose mem0, also add `mem0ai` (Python: `DEPS_VETTED=1 uv add mem0ai`; for other languages, add the equivalent client or leave a clearly-marked note in `docs/requirements.md` if none is established).

**Then install.** If `{{USES_DEVCONTAINER}}` is `no`:

1. Verify the chosen package manager is available (the bootstrap should have caught this for known languages; verify again here for safety).
2. Run `{{INSTALL_COMMAND}}` to install deps from the manifest file.
3. Smoke-test:
   - Python: `uv run python -c "import sys; print(f'Python {sys.version.split()[0]} venv ready')"`
   - TypeScript: `node -e "console.log('Node ' + process.version + ' ready')"`
   - Rust: `cargo --version`
   - Go: `go version`
4. If install fails, leave the scaffold in place (do not roll back). Report the failing dep and ask the user to fix the manifest then re-run install.

If `{{USES_DEVCONTAINER}}` is `yes`: append the capability deps to the manifest, but **skip the install**. Deps will install inside the container.

### Phase 5: Verify and report

First, confirm the **core** files (every project, every language) exist:

```bash
test -f AGENTS.md && test -f README.md && test -f .env.example && \
test -f .mcp.json && test -f .claude/.template-version && \
test -f .github/workflows/qa.yml && test -f .github/pull_request_template.md && \
test -d docs && test -f docs/PRODUCT_VISION.md && test -f docs/SECURITY.md && \
test -f docs/language-standards.md && \
test -f docs/agents.md && test -f docs/agents.json && \
test -f docs/designs/README.md && test -f docs/probes/README.md && test -f docs/ships/README.md
```

Then, ONLY when `claude-code` is in the B13 roster, confirm the enforcement
tree landed:

```bash
test -L CLAUDE.md && test -d .claude/agents && \
test -f .claude/agents/security-reviewer.md && test -f .claude/agents/tech-debt.md && \
test -f .claude/agents/utility.md && \
test -f .claude/settings.json && test -f .claude/hooks/deps-guard.sh && \
test -f .claude/hooks/slice-audit.sh && test -x .claude/hooks/slice-audit.sh && \
test -f .claude/skills/select-agents/SKILL.md
```

When `claude-code` is NOT in the roster: skip that block, and tell the user
the bootstrap-installed `.claude/skills/` trees (init-project itself and the
Phase 1 skill pack) are inert for their agents and safe to delete.

Then confirm the chosen profile landed: its manifest (`{{MANIFEST_FILE}}`) exists, and the green-scaffold source + test exist (Python `src/example.py`+`tests/test_example.py`; TypeScript `src/example.ts`+`tests/example.test.ts`; Go `greet.go`+`greet_test.go`; Rust `src/lib.rs` (with its in-file unit test) + `tests/e2e.rs` + `rust-toolchain.toml`).

Then check no unresolved placeholders remain:

```bash
! grep -rn '{{[A-Z0-9_]*}}' . --include='*.md' --include='*.txt' --include='*.toml' --include='*.yml' --include='*.yaml' --include='*.json' --include='*.sh' --include='*.py' --include='*.ts' --include='*.go' --include='*.rs' --include='*.mod' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=skills 2>/dev/null
```

(`--exclude-dir=skills` skips only the installed skill trees under `.claude/skills/`; the generated `.claude/hooks/` and `.claude/agents/` files ARE checked -- they carry substituted values.)

Finally, **run the quality gate** (inside the dev container if one is used): `{{QA_COMMAND}}`. Every complete profile ships a green-on-first-run scaffold, so the gate must pass on the first run. If it is not green, fix the scaffold before handing off -- a project that starts red is a bug.

Once verification passes, delete the renderer input: `rm docs/_init-answers.json` (its content lives on in the rendered docs).

Report what was generated, then hand off:

> "Bootstrap complete. Your project is ready. Next steps:
> 1. {{If dev container}}: Reopen in dev container, then run `{{INSTALL_COMMAND}}` inside. {{Else}}: Deps are already installed; `{{QA_COMMAND}}` is green on the fresh scaffold. Use `{{FIX_COMMAND}}` to auto-format locally.
> 2. Initialize git: `git add . && git commit -m 'chore: bootstrap project'`. Push to enable CI.
> 3. Restart Claude Code so `.mcp.json` (Context7) registers.
> 4. Start your first task -- replace `src/example.py` and `tests/test_example.py` with your first slice."

Then, if the repo has a GitHub remote and `gh` is available, offer (do not run unasked) to enable branch protection -- the generated CI is merge-blocking only once the repo requires its checks:

```bash
gh api -X PUT "repos/{owner}/{repo}/branches/main/protection" \
  -F 'required_status_checks[strict]=true' \
  -F 'required_status_checks[contexts][]=qa' \
  -F 'required_status_checks[contexts][]=e2e' \
  -F 'required_status_checks[contexts][]=ship-audit' \
  -F 'enforce_admins=false' -F 'required_pull_request_reviews=null' -F 'restrictions=null'
```

Explain the trade-off in one line: without this, a red build can still be merged by pushing directly.

---

## Placeholder substitution

Templates use `{{PLACEHOLDER}}` syntax. **`render.py` performs every
substitution** -- these tables are the reference map of what each placeholder
means and which answer (or profile value) feeds it. Do not substitute by hand.
Any new placeholder must be added here, to the answers schema (or
`profile.json`), and to `render.py`'s mapping, together.

### Universal placeholders (asked or derived)

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | A1 |
| `{{PROJECT_GOAL}}` | A1 |
| `{{PROJECT_SLUG}}` | A1 -- derived: lowercase, hyphenated, valid package/module identifier |
| `{{PRIMARY_USER}}` | A1 |
| `{{CORE_PROBLEM}}` | A2 |
| `{{CORE_JOURNEY}}` | A2 (the heart: the core user-visible flow, as steps) |
| `{{SUCCESS_MEASURE}}` | A2 (what success looks like, concretely) |
| `{{RISKIEST_ASSUMPTION}}` | A2 (the assumption that sinks the project if wrong) |
| `{{REQ_AC_LIST}}` | A3 -- rendered as `- [ ] **REQ-ACn:** <criterion>` lines |
| `{{NON_GOALS}}` | A4 (bullet list) |
| `{{OTHER_USERS}}` | A9 (bullet list; `- none identified yet` if empty) |
| `{{CONSTRAINT_TIME}}` | A5 |
| `{{CONSTRAINT_COST}}` | A5 (includes LLM/API budget when AI is in scope) |
| `{{CONSTRAINT_DATA}}` | A5 |
| `{{FIRST_MILESTONE}}` | A5 -- derived date or `none set` |
| `{{DEPLOYMENT_TARGET}}` | A6 |
| `{{SCALE_EXPECTATIONS}}` | A7 |
| `{{INTEGRATIONS}}` | A8 (bullet list; `- none` if none) |
| `{{PAIN_POINT}}` | A2 (positioning) |
| `{{PRODUCT_CATEGORY}}` | A2 (positioning) |
| `{{CURRENT_ALTERNATIVE}}` | A2 (positioning) |
| `{{KEY_BENEFIT}}` | A2 (positioning) |
| `{{KEY_DIFFERENTIATOR}}` | A2 (positioning) |
| `{{IN_SCOPE_LIST}}` | Derived from A2 core flow + A3 criteria (bullet list) |
| `{{SUCCESS_METRICS}}` | A2 success measure rendered as 1-3 `- <metric> -- target` lines |
| `{{READS_UNTRUSTED}}` | B8 (`yes`/`no`) |
| `{{HOLDS_PRIVATE_DATA}}` | B8 (`yes`/`no`) |
| `{{ACTS_OUTWARD}}` | B8 (`yes`/`no`) |
| `{{E2E_BROWSER_INSTALL_STEP}}` | Derived from B2 + profile `e2e_browser_install` (renderer rule 12) |
| `{{LANGUAGE}}` | B1 |
| `{{HAS_FRONTEND}}` | B2 |
| `{{BACKEND_FRAMEWORK}}` | B3 |
| `{{AI_FEATURES}}` | B4 (comma-separated) |
| `{{VECTOR_DB}}` | B4 |
| `{{LLM_PROVIDER}}` | B5 |
| `{{EMBEDDINGS_MODEL}}` | B5 |
| `{{DATABASE}}` | B6 |
| `{{USES_DEVCONTAINER}}` | B7 (`yes`/`no`) |
| `{{POSITIVE_REFERENCE_TEXT}}` | A10 -- rendered line (Phase 4 renderer table, rule 5) |
| `{{NEGATIVE_REFERENCE_TEXT}}` | A10 -- rendered line, may be empty |
| `{{MEMORY_DOC_LINE}}` | Derived from B11 (`templates/conditional/memory-doc-line.md`, or empty) |
| `{{AI_DISCIPLINE_BLOCK}}` | Derived from B4 (`templates/conditional/ai-discipline.md`, or empty) |
| `{{CODEX_REVIEW_STEP}}` | Derived from B12 -- `templates/conditional/codex-review-step.md`, or empty |
| `{{CODEX_ROSTER_NOTE}}` | Derived from B12 -- `templates/conditional/codex-roster-note.md`, or empty |
| `{{AGENT_MATRIX}}` | Derived from B13 -- per-agent sections from `templates/conditional/agents/`, joined |
| `{{DATE}}` | today, ISO format (`date` in the answers file) |

B9 (`explanations`), B10 (`seed_gotchas`), and B11 (`mem0`) have no placeholder of their own: they are switches in the answers file's `opt_ins` section that turn renderer rules 6-8 on or off. B8 (security profile) renders its three `yes`/`no` placeholders above and additionally seeds the threat model (renderer rule 10).

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

---

## Language profiles

The YAML blocks below are the human-readable profile reference (commands for
Phase 4.5, CI notes, conventions). The renderer consumes the machine-readable
copy at `templates/profiles/<lang>/profile.json` -- when you change a value
here, change it there too (CI cross-checks the load-bearing scalars).

### Python (fully supported)

```yaml
language_version: "3.12+"
file_extension: "py"
package_manager: "uv"
manifest_file: "pyproject.toml"
install_command: "uv sync"
add_dep_command: "uv add"
qa_command: "uv run qa"
fix_command: "uv run fix"
e2e_command: "bash scripts/e2e.sh"
e2e_browser_install: "uv run playwright install --with-deps chromium"
test_runner: "pytest"
test_command: "uv run pytest -m 'not e2e'"
lint_tool: "ruff"
lint_command: "uv run ruff check ."
format_tool: "ruff format"
format_command: "uv run ruff format --check ."
type_tool: "mypy"
type_command: "uv run mypy src/"
precommit_install_command: "uv run pre-commit install"

ci_setup_steps: |
  - name: Set up uv
    uses: astral-sh/setup-uv@d4b2f3b6ecc6e67c4457f6d3e41ec42d3d0fcb86 # v5
    with:
      enable-cache: true
  - name: Set up Python
    run: uv python install 3.12
  - name: Install deps
    run: uv sync

precommit_hooks: |
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.8
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

library_docs_urls: |
  ### Core stack
  - **uv**: https://docs.astral.sh/uv/
  - **ruff**: https://docs.astral.sh/ruff/
  - **mypy**: https://mypy.readthedocs.io/
  - **pytest**: https://docs.pytest.org/
  - **Pydantic v2**: https://docs.pydantic.dev/latest/
  - **pydantic-settings**: https://docs.pydantic.dev/latest/concepts/pydantic_settings/

  ### AI / RAG (use Context7 first)
  - **OpenAI SDK**: https://github.com/openai/openai-python
  - **Anthropic SDK**: https://github.com/anthropics/anthropic-sdk-python
  - **LangChain**: https://python.langchain.com/docs/introduction/
  - **Chroma**: https://docs.trychroma.com/
  - **pgvector**: https://github.com/pgvector/pgvector

  ### Frontend (if applicable)
  - **Streamlit**: https://docs.streamlit.io/
  - **Gradio**: https://www.gradio.app/docs

notes:
  type_annotations: |
    - Python 3.12+ syntax: `list[int]` not `List[int]`. `dict[str, X]` not `Dict[str, X]`.
    - Every function signature fully typed, including return types.
    - `from __future__ import annotations` at the top of every module.
  imports: |
    - Order: stdlib -> third-party -> local. Sorted by ruff (`I` rule set).
    - One module per import line for stdlib and third-party.
    - If a name is used ONLY in annotations, ruff's TC rules will move it under `if TYPE_CHECKING:` -- but a name a framework resolves at RUNTIME from the annotation (e.g. FastAPI's `Request`/`Response`/`UploadFile` in route signatures) must stay a real import. Keep those imports at runtime and mark them `# noqa: TC002` if flagged.
  async: |
    - Match the project shape: in a server or any concurrent context, I/O (HTTP, DB, LLM) should be `async`. In a CLI, script, batch job, or library with no concurrency, plain sync is simpler and fine -- do not add async for its own sake.
    - When you do go async, use `asyncio.TaskGroup` (Python 3.11+) for concurrent work, and keep the whole I/O path async (no sync calls blocking the loop).
  errors: |
    - Specific exception classes per domain. Never bare `Exception`.
    - Fail-closed on safety/security: if uncertain, refuse rather than proceed.
    - Framework dependency-injection defaults (e.g. FastAPI `Depends(...)`) are called markers, not values: never replace `Depends(get_settings)` with a bare `get_settings()` call at import time -- the first form resolves per-request, the second freezes one instance at import and 500s under test overrides.
  config: |
    - `pydantic-settings` for all configuration.
    - Never hardcode API keys, URLs, or model names. Pull from env or settings.
  logging: |
    - `logging` module, not `print`.
    - Structured log lines (JSON if going to ingest, key=value otherwise).
  test_layout: |
    - `tests/` mirrors `src/` structure. Unit + functional tests run in the fast gate.
    - `tests/e2e/` holds end-to-end tests marked `@pytest.mark.e2e`; they are excluded from the fast gate and run via `scripts/e2e.sh` in CI. For a UI use `pytest-playwright` (headless browser); for API-only assert the full request -> response -> persisted-state path.
    - Security/red-team tests are marked `@pytest.mark.security` and follow the `docs/SECURITY.md` checklist.
    - Use `pytest-asyncio` for async tests. Inject fakes via fixtures/dependency objects; no mocks for code you own.
    - `factory-boy` or hand-rolled fixtures in `tests/fixtures/` for data.
    - `hypothesis` for property-based tests on pure functions.
    - `--import-mode=importlib` is set in addopts: test files may share basenames across folders without `__init__.py` shims.
  precommit_hooks: |
    This profile ships `.pre-commit-config.yaml` with `ruff` (`--fix`) and `ruff-format`, plus the generic hooks (trailing-whitespace, yaml/toml/json validation, large-file guard). Install once with `uv run pre-commit install`. (TypeScript, Go, and Rust profiles ship no pre-commit; their `qa` gate + CI are the enforcement.)
```

### TypeScript (complete)

Files live in `templates/profiles/typescript/`. The gate is expressed as npm scripts in `package.json` (qa is verify-only; fix mutates; e2e is separate). Ships no pre-commit config.

```yaml
language_version: "Node 22 (LTS) / TypeScript 5.7+"
file_extension: "ts"
package_manager: "npm"
manifest_file: "package.json"
install_command: "npm install"
add_dep_command: "npm install"
qa_command: "npm run qa"
fix_command: "npm run fix"
e2e_command: "npm run e2e"
e2e_browser_install: "npx playwright install --with-deps chromium"
test_runner: "vitest"
test_command: "npx vitest run"
lint_tool: "eslint"
lint_command: "npx eslint ."
format_tool: "prettier"
format_command: "npx prettier --check ."
type_tool: "tsc"
type_command: "npx tsc --noEmit"
precommit_install_command: ""   # TypeScript profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Node
    uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
    with:
      node-version: "22"
      cache: "npm"
  - name: Install deps
    run: npm ci

library_docs_urls: |
  ### Core stack
  - **TypeScript**: https://www.typescriptlang.org/docs/
  - **Vitest**: https://vitest.dev/
  - **ESLint (flat config)**: https://eslint.org/docs/latest/
  - **typescript-eslint**: https://typescript-eslint.io/
  - **Prettier**: https://prettier.io/docs/
  - **Playwright**: https://playwright.dev/docs/intro

notes:
  type_annotations: |
    - `strict: true`. Annotate every exported function's params and return type; let inference handle locals. Prefer `unknown` over `any`; never `as any` or `// @ts-ignore`.
  imports: |
    - ES modules only (`"type": "module"`). `import`/`export`, never `require`. Use `import type { X }` for type-only imports.
  async: |
    - Server/concurrent context: I/O is `async`/`await`. CLI/library with no concurrency: plain sync is fine -- do not add async for its own sake. Never leave a floating promise.
  errors: |
    - Throw `Error` subclasses per domain; never throw strings. Fail closed on safety/security.
  config: |
    - Read `process.env` at one boundary; validate it (e.g. zod) into a typed config. Secrets in `.env` (gitignored), never hardcoded.
  logging: |
    - Structured logger (`pino`) or `console` with structured fields; no scattered `console.log` in committed code.
  test_layout: |
    - `tests/` mirrors `src/`; unit + functional (`*.test.ts`) run in the fast gate via `vitest run`. `tests/e2e/` holds Playwright specs, excluded from the fast gate, run via `npm run e2e`.
    - Inject fakes via params/factories; avoid mocking modules you own.
  precommit_hooks: |
    - Not used. The TypeScript profile ships no `.pre-commit-config.yaml`; `npm run qa` (local + CI) is the gate.
```

### Go (complete)

Files live in `templates/profiles/go/`. The gate is `scripts/qa.sh` (verify-only: gofmt-check, vet, golangci-lint, test); fix mutates; e2e is build-tag gated (`//go:build e2e`). Ships no pre-commit config.

```yaml
language_version: "1.25+"
file_extension: "go"
package_manager: "go mod"
manifest_file: "go.mod"
install_command: "go mod download"
add_dep_command: "go get"
qa_command: "bash scripts/qa.sh"
fix_command: "bash scripts/fix.sh"
e2e_command: "bash scripts/e2e.sh"
e2e_browser_install: ""   # Go e2e is API/CLI-level by default (no browser)
test_runner: "go test"
test_command: "go test -race ./..."
lint_tool: "golangci-lint"
lint_command: "golangci-lint run"
format_tool: "gofmt"
format_command: "gofmt -l ."   # CHECK form (lists unformatted files); fix.sh does -w
type_tool: "go build"
type_command: "go build ./..."
precommit_install_command: ""   # Go profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Go
    uses: actions/setup-go@40f1582b2485089dde7abd97c1529aa768e1baff # v5
    with:
      go-version: "1.25"
      cache: true
  - name: Download modules
    run: go mod download
  - name: Install golangci-lint (pinned + checksum-verified)
    run: |
      curl -sSfL -o /tmp/golangci-install.sh https://raw.githubusercontent.com/golangci/golangci-lint/v2.12.2/install.sh
      echo "d32d3534af96cfd59546a084d22b213e8a47541cada5013aa8a84c4fa2589905  /tmp/golangci-install.sh" | sha256sum -c -
      sh /tmp/golangci-install.sh -b "$(go env GOPATH)/bin" v2.12.2
      echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"

library_docs_urls: |
  ### Core stack
  - **Effective Go (idioms)**: https://go.dev/doc/effective_go
  - **Managing dependencies**: https://go.dev/doc/modules/managing-dependencies
  - **testing package**: https://pkg.go.dev/testing
  - **golangci-lint**: https://golangci-lint.run/

notes:
  type_annotations: |
    - Statically typed; the compiler is the type checker (`go build ./...`). Explicit types on exported signatures; `:=` for obvious locals. Keep zero values meaningful.
  imports: |
    - Group stdlib / third-party / local, blank-line separated. `goimports` (fix.sh) sorts and prunes. Unused imports fail compilation.
  async: |
    - Concurrency is goroutines + channels, only where it earns its keep; CLI/script/library stays sequential. Use `context.Context` on I/O paths; never leak goroutines.
  errors: |
    - Return `error` last; check it immediately. Wrap with `fmt.Errorf("...: %w", err)`; inspect with `errors.Is`/`As`. Reserve `panic` for unrecoverable state. Fail closed.
  config: |
    - Config from env (`os.Getenv`) or flags; never hardcode keys/URLs/models. Secrets out of source and `go.mod`.
  logging: |
    - `log/slog` (structured), not `fmt.Println`, for application logs.
  test_layout: |
    - `_test.go` files beside the code (`package app`) run in the fast gate via `go test ./...`. `tests/e2e/` is `//go:build e2e`-gated, excluded from the fast gate, run via `scripts/e2e.sh`.
    - Table-driven tests + `t.Run` subtests. Inject fakes via interfaces you own; avoid mocking frameworks.
  precommit_hooks: |
    - Not used. The Go profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.
```

### Rust (complete)

Files live in `templates/profiles/rust/`. The gate is `scripts/qa.sh` (verify-only: line cap, fmt-check, clippy with warnings-as-errors, check, test); fix mutates; e2e tests are `#[ignore]`-tagged in `tests/e2e.rs` and run via `scripts/e2e.sh`. The toolchain (compiler + clippy + rustfmt) is pinned by `rust-toolchain.toml`, which rustup honors everywhere (local, dev container, CI). The manifest ships as a plain `Cargo.toml` (no `.example` suffix needed: cargo never scans nested directories, so the template copy is inert -- unlike Python's `pyproject.toml`). Ships no pre-commit config.

```yaml
language_version: "1.96 (edition 2024; pinned by rust-toolchain.toml)"
file_extension: "rs"
package_manager: "cargo"
manifest_file: "Cargo.toml"
install_command: "cargo fetch"
add_dep_command: "cargo add"
qa_command: "bash scripts/qa.sh"
fix_command: "bash scripts/fix.sh"
e2e_command: "bash scripts/e2e.sh"
e2e_browser_install: ""   # Rust e2e is API/CLI-level by default (no browser)
test_runner: "cargo test"
test_command: "cargo test"
lint_tool: "clippy"
lint_command: "cargo clippy --all-targets -- -D warnings"
format_tool: "rustfmt"
format_command: "cargo fmt --check"   # CHECK form; fix.sh runs `cargo fmt` (write)
type_tool: "cargo check"
type_command: "cargo check"
precommit_install_command: ""   # Rust profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Rust
    # Installs the toolchain pinned in rust-toolchain.toml (channel + the
    # clippy/rustfmt components) and enables cargo caching. rustflags is
    # cleared so the scripts alone define strictness (qa runs clippy with
    # -D warnings); the action would otherwise export RUSTFLAGS="-D warnings"
    # and make plain builds stricter in CI than locally.
    uses: actions-rust-lang/setup-rust-toolchain@166cdcfd11aee3cb47222f9ddb555ce30ddb9659 # v1
    with:
      rustflags: ""
  - name: Fetch dependencies
    run: cargo fetch

library_docs_urls: |
  ### Core stack
  - **The Rust Book**: https://doc.rust-lang.org/book/
  - **Standard library**: https://doc.rust-lang.org/std/
  - **The Cargo Book**: https://doc.rust-lang.org/cargo/
  - **Clippy lint list**: https://rust-lang.github.io/rust-clippy/master/
  - **rustfmt**: https://github.com/rust-lang/rustfmt

notes:
  type_annotations: |
    - Statically typed; the compiler is the type checker (`cargo check`). Explicit types on public signatures; let inference handle locals. Prefer borrowed views (`&str`, `&[T]`) for parameters and owned types for returns.
  imports: |
    - `use` statements at the top, grouped stdlib / third-party / crate-local, blank-line separated (rustfmt keeps each group sorted). No wildcard imports outside preludes and test modules.
  async: |
    - Add async (tokio) only when the project is genuinely concurrent (server, many parallel I/O calls); a CLI, batch job, or library stays synchronous -- do not add an async runtime for its own sake. When async, keep the whole I/O path async and never block the executor (no `std::thread::sleep` or sync file I/O inside it).
  errors: |
    - Return `Result<T, E>` with a domain error enum (`thiserror` in libraries; `anyhow` acceptable at the application boundary). No `unwrap()`/`expect()` outside tests and provably-infallible spots; `?` for propagation; `panic!` only for unrecoverable invariants. Fail closed on safety/security.
  config: |
    - Read env at one boundary into a typed config struct; never hardcode keys/URLs/models. Secrets in `.env` (gitignored), never in source or Cargo.toml.
  logging: |
    - `tracing` (structured, with spans) for application logs -- not `println!`.
  test_layout: |
    - Unit tests live beside the code in `#[cfg(test)] mod tests` blocks; integration tests in `tests/`; both run in the fast gate via `cargo test`. `tests/e2e.rs` is `#[ignore]`-tagged, excluded from the fast gate, run via `scripts/e2e.sh` (`cargo test --test e2e -- --ignored`).
    - Table-style cases via loops over input/expected pairs; inject fakes via traits you own; avoid mocking frameworks.
  precommit_hooks: |
    - Not used. The Rust profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.
```

### Experimental languages (Other)

"Other" has **no profile** -- there is no profile folder to copy, so a generated project would be core-only with no working toolchain. Do not imply otherwise. Get explicit consent first:

> "Heads up: that language isn't a built profile yet. I can lay down the universal core (AGENTS.md, docs, security files, CI shape), but you'd have to build the toolchain yourself -- there's no validated manifest, lint/format/type setup, qa/fix scripts, or green scaffold -- so the first quality-gate run won't pass until you complete it. Proceed on that basis, switch to Python/TypeScript/Go/Rust, or have me add a profile for it properly first?"

If they proceed: `render.py` cannot run without a `profile.json`, so this is the ONE path where generation is manual -- copy `templates/core/` only, substitute the discovery placeholders from the answers file by hand, leave clearly-marked TODOs for the toolchain placeholders in `docs/language-standards.md` and `.github/workflows/qa.yml`, do NOT generate a manifest or scripts, and tell them the gate is not green until they finish the toolchain. The better path is to add a real profile under `templates/profiles/<lang>/` (see the repo `AGENTS.md` `<adding-a-language-profile>`) so the experience matches the complete profiles.

---

## Failure modes and how to handle them

**The user can't decide on a language.**
Python, TypeScript, Go, and Rust are all complete profiles; default to Python if there is no other signal. Don't let analysis paralysis block progress.

**The user wants to skip the interview.**
OK for Part B (stack): require only language + dev container and default the
rest. Part A cannot be fully skipped -- minimum: name, one-sentence goal, the
core flow, and at least one acceptance criterion. Explain why: every Part A
answer that is missing ships as a TODO that later becomes a surprise, which is
the exact failure this template exists to prevent. Mark whatever the user still
refuses as explicit `TODO(interview-skipped)` so it is greppable.

**The user wants to bootstrap into a non-empty directory.**
Refuse unless they explicitly confirm overwriting. Show what would be overwritten first.

**Skill installation fails (no npm/node).**
This is a hard failure. The `tdd` skill is required. Stop and ask the user to install Node.js, then re-run.

**Package manager not available for chosen language.**
Stop with a clear install link for the chosen language's package manager (`uv`, `pnpm`, `cargo`, `go`).

**Context7 MCP fails to start after bootstrap.**
Check that `npx` is available. The Context7 server in `.mcp.json` uses `npx -y @upstash/context7-mcp@3.2.3`. If npx is broken, document the failure in `docs/gotchas.md` and instruct the user to either fix npx or remove the Context7 entry from `.mcp.json`.

---

## After bootstrap: how the system works

Once bootstrap completes, the project enters normal mode. The agent should:

1. Read `AGENTS.md` on every new conversation
2. Read `docs/structure.txt`, `docs/requirements.md`, and `docs/language-standards.md` first when starting work; read `docs/SECURITY.md` for any task touching auth, input, external content, or tools -- the main-context driver reads this doc set once per session; subagent briefs name the docs each task needs, not the full set every hop
3. Run the `<planning-discipline>` pass before EVERY non-trivial slice or new feature, not only the first: brainstorm the options, then grill the chosen one (with `grill-me`) -- name the full test plan (unit + functional + e2e + security) before writing code, build the mockup first when the slice makes a significant UI/UX choice, and write the design memo (docs/designs/) -- the user must approve it before any code (see <investigation-discipline>)
4. Use `docs/current-task/task.md` as shared memory across agents during a task
5. Use the upstream `tdd` skill (mattpocock/skills) for the Red to Green to Refactor methodology
6. Delegate to subagents (`@test-spec-writer`, `@implementer`, `@code-reviewer`) for complex phases; run `@security-reviewer` and `@tech-debt` on their recurring cadence
7. Override subagent models per call (`model: haiku | sonnet | opus` in the Agent invocation) to match cost to complexity
8. Query Context7 (via the `.mcp.json` MCP server) for library API details rather than relying on training memory
9. Update `docs/gotchas.md`, `docs/structure.txt`, and `docs/SECURITY.md` when a task surfaces a lesson or changes layout/attack surface

This skill is no longer needed after bootstrap. It can be deleted from `.claude/skills/` if the user wants to keep the project minimal.
