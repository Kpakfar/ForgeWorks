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

Save answers to a temporary file `docs/_init-answers.md` as you go (this will be deleted after generation).

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
KEY DIFFERENTIATOR versus that alternative?

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
  4) Rust         (cargo, clippy, rustfmt)             [not yet -- experimental]
  5) Other        (manual setup)                       [not yet -- experimental]
```

Python, TypeScript, and Go each have a **complete profile** (`templates/profiles/<lang>/`) with a working toolchain and a green-on-first-run scaffold -- pick any of them and the quality gate passes immediately. Rust and "Other" are not yet built; see "Experimental languages" below before generating one.

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

> "Do you have the Codex CLI available? If so, the code-reviewer can run an independent Codex pass for a second perspective on important changes."

Yes / No. Default: No. If yes, the generated `code-reviewer` agent includes a step to invoke Codex and reconcile its findings.

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
> opt-ins: memos {y/n}, gotchas seed {y/n}, mem0 {y/n}, Codex {y/n}.
>
> This will create approximately {N} files. Proceed?"

Wait for confirmation and apply corrections before Phase 4.

### Phase 4: Generate the scaffold

A generated project is **the universal core plus exactly one language profile** -- nothing from any other language is ever copied in. Two source folders:

- `templates/core/` -- language-free files every project gets (AGENTS.md, docs/, `.mcp.json`, the CI workflow shape, PR template, README, .env.example, `.claude/`).
- `templates/profiles/<language>/` -- the chosen language's files (manifest, toolchain config, `scripts/` or package scripts, the green scaffold, `.gitignore`, dev container, and -- only where the language uses it -- a pre-commit config).

For each file in `templates/core/` AND in `templates/profiles/{{LANGUAGE}}/`:

1. Read the template file.
2. Substitute placeholders (see "Placeholder substitution" + the chosen language profile below).
3. Write it to the project root at the corresponding path, applying these **explicit source -> target renames** (a few profile files carry a suffix so the template repo does not treat them as live config):
   - Python: `pyproject.toml.example` -> `pyproject.toml`.
   - Any other `*.example` manifest a profile ships -> drop the `.example` suffix.
   Do not rely on inference: a literal copy that leaves `pyproject.toml.example` makes `{{INSTALL_COMMAND}}` and Phase 5 fail.
4. **Skip any `.devcontainer/` if `{{USES_DEVCONTAINER}}` is `no`.**

Do NOT read or copy `templates/profiles/<other-language>/`. The manifest, scripts, scaffold, dev container, `.gitignore`, and (Python-only) pre-commit config all come from the chosen profile, so the project carries only its own language's tooling and libraries. The core files reference the toolchain through placeholders (`{{QA_COMMAND}}`, `{{CI_SETUP_STEPS}}`, ...) filled from the profile's YAML.

**Multi-line placeholders must be re-indented (do not skip -- plain replace breaks YAML):**
`{{CI_SETUP_STEPS}}` (in `.github/workflows/qa.yml`, at 6-space indent) and `{{LANGUAGE_PRECOMMIT_HOOKS}}` (in `.pre-commit-config.yaml`, at 2-space indent) are multi-line values written at column 0 in the profile YAML. A literal string-replace indents only the first line and produces invalid YAML. When substituting a multi-line value, prefix EVERY line after the first with the placeholder's own indentation (the column where `{{` sits). Verify the result parses as YAML before moving on.

**Identifiers and escaping (do not skip -- raw display values break structured files):**
- Use `{{PROJECT_SLUG}}` (not `{{PROJECT_NAME}}`) for every identifier field: the package name in `pyproject.toml`/`package.json` and the module path in `go.mod`. A display name like `My Project` is not a valid TOML package name or Go module path.
- When you substitute a display value (`{{PROJECT_NAME}}`, `{{PROJECT_GOAL}}`, ...) into a structured file (JSON, TOML, YAML, `go.mod`), escape it for that format: in JSON escape `"`, `\`, and control characters; in TOML escape `"` or use a literal string. A goal like `A "quoted" goal` must not produce invalid JSON in `package.json`. Display values flow unescaped only into Markdown prose.

**Conditional content (from interview answers):**

After the base substitution pass, apply these rules:

0. **AI discipline block (B4).** If any AI feature was selected (RAG, agents, evals, streaming), render `{{AI_DISCIPLINE_BLOCK}}` in `AGENTS.md` as the block below. If no AI feature was selected, render it as an empty string.

   ```
   <!-- FW-BLOCK: ai-discipline v2.0.0 -->
   <ai-discipline>
   These rules apply because this project uses prompts, LLMs, or agentic flows.

   - **Prompts as plain text files.** Store every system prompt as a `.md` (or `.txt`) file under a `prompts/` directory. Load them with short helpers. Substitute variables with plain string `.replace("{{placeholder}}", value)` (or the language's equivalent). Do NOT build template-engine-style, ORM-style, or class-based prompt builders. The loader module should be small.

   - **Prompt variants are files, not classes.** If you need multiple versions of the same prompt (zero-shot, few-shot, chain-of-thought, persona A, persona B), save them as separate files and switch by filename via a config or session-state value. No strategy pattern, no registry, no factory.

   - **Validate every LLM response.** Use the language's structured-output validation on every LLM response that downstream code depends on. Fail closed on schema mismatch.

   - **AI-shaped modules each in their own file.** If this project has an LLM client, a prompt loader, a retriever, an ingestion pipeline, tools, or a safety check, each is its own file. Same ~100 / 200 line caps as the core rule.

   - **Security (LLM/agent).** This project can be prompt-injected. Never let one agent read untrusted content, hold private data, AND act on the outside world (the lethal trifecta) -- break one leg: split the agent, drop a capability, or gate the action behind a human. Treat every ingested input and every model response as untrusted: sanitize at ingest, fence untrusted text as data (never as instructions), validate each response against a schema and fail closed, and filter output before it is shown or stored. No tool may act on an attacker-chosen id; bind tools to the session owner. Full threat model and red-team checklist: `docs/SECURITY.md`.
   </ai-discipline>
   <!-- /FW-BLOCK: ai-discipline -->
   ```

1. **Style references (A10).** Render `{{POSITIVE_REFERENCE_TEXT}}` and `{{NEGATIVE_REFERENCE_TEXT}}` in `AGENTS.md`:
   - Positive reference provided: `Pattern-match every file you write or modify to <ref>. Reference material: <location>.`
   - Positive is TBD: `<!-- No positive reference yet. Add one to this block when you choose one. -->`
   - Negative reference provided: `Explicitly avoid the shape of <ref>. Anti-pattern material: <location>.`
   - No negative reference: empty string.

2. **Per-slice explanation memos (B9).** If `{{GENERATE_EXPLANATIONS}}` is `no`: delete `docs/explanations/` from the generated tree. If `yes`: leave the README in place (it ships in the template).

3. **Gotchas seed (B10).** If `{{SEED_GOTCHAS}}` is `yes`: append the three starter entries below to `docs/gotchas.md`, inserted between the `## Entries` heading and the `## Generic lessons` section.

   ```
   ### [General] Patch the cause, not the symptom
   **Symptom:** a failure was fixed but the same bug recurs with a different shape.
   **Cause:** the fix patched the surface (special case, magic string, swallowed exception) instead of the underlying category (bad input, wrong config, dependency version, race, missing edge case).
   **Fix:** identify which category the cause is in first; fix at that level.
   **Date / Task:** seeded by `/init-project`.

   ### [General] Trust artifacts, not summaries
   **Symptom:** a subagent reported success; the actual artifact (test run, metric, file change) told a different story.
   **Cause:** subagent summaries describe intent, not reality.
   **Fix:** open the artifact on disk, run the test yourself, or grep the file before trusting any "done" claim.
   **Date / Task:** seeded by `/init-project`.

   ### [General] Handle external I/O at one boundary, not everywhere
   **Symptom:** a single transient failure (a DNS blip, a momentary 5xx, a dropped connection) aborted a whole multi-step run.
   **Cause:** the error propagated raw from deep inside the flow; nothing between the call site and the top retried or degraded it, and the framework did not absorb it either.
   **Fix:** wrap each external call (network, third-party API, tool) at a single boundary that retries transient errors with backoff and then degrades gracefully (empty result + a logged warning). One dead call then costs a call, not the run; a real outage still ends loudly after the retry budget.
   **Date / Task:** seeded by `/init-project`.
   ```

4. **mem0 (B11).** If `{{USE_MEM0}}` is `yes`:
   - Keep `docs/memory.md` in the generated tree.
   - Render `{{MEMORY_DOC_LINE}}` in `AGENTS.md` as: `- \`docs/memory.md\` : memory scopes (User, Session, Agent), what is stored, what is not.`
   - Insert this block into `AGENTS.md` between `<library-docs>` and `<tools>`:

     ```
     <!-- FW-BLOCK: memory v2.0.0 -->
     <memory>
     This project uses **mem0** for persistent memory across sessions.

     **Scopes:**
     - User: facts about the human (preferences, profile, history).
     - Session: facts about the current interaction.
     - Agent: facts the agent itself has confirmed during work.

     **Before writing memory code:**
     - Decide which scope a piece of data belongs in. If you cannot say, do not store it.
     - Update `docs/memory.md` with the new schema entry.
     - Verify the API against Context7 for the pinned `mem0ai` version.

     **Library docs:** https://docs.mem0.ai/
     </memory>
     <!-- /FW-BLOCK: memory -->
     ```

   - Add `mem0ai` to the chosen language's manifest (for Python: `DEPS_VETTED=1 uv add mem0ai` -- the `DEPS_VETTED=1` prefix is how the deps-guard hook lets a vetted install through). For language profiles not implemented, leave a TODO note in `requirements.md`.

   If `{{USE_MEM0}}` is `no`: delete `docs/memory.md`, render `{{MEMORY_DOC_LINE}}` as an empty string, do not insert the `<memory>` block, do not add the dep.

5. **Security profile (B8).** `docs/SECURITY.md`, `.claude/settings.json` (deps-guard hook), `.claude/hooks/deps-guard.sh`, and `.claude/agents/security-reviewer.md` always ship -- the universal risks (access control, secrets, supply chain) apply to every project. Then adjust for the AI answer:
   - If **any AI feature** was selected (B4): remove only the fence comment lines (`<!-- AI-SECURITY-START/END -->`, `<!-- AI-REDTEAM-START/END -->` in `docs/SECURITY.md`; `<!-- AI-FEATURES-START/END -->` in `docs/requirements.md`; `<!-- AI-IMPL-START/END -->` in `.claude/agents/implementer.md`; `<!-- AI-REVIEW-START/END -->` in `.claude/agents/code-reviewer.md`) and keep the content.
   - If **no AI feature** was selected: delete the whole fenced blocks (markers and everything between) in all four files -- the AI sections of `docs/SECURITY.md`, the `## AI features in scope` block of `docs/requirements.md`, and the AI-specific rules in the implementer and code-reviewer subagents. A non-AI project ships no AI/RAG rules or TODOs anywhere.
   - Seed the `## Attack surface` table and the trifecta line from the B8 answers (reads untrusted / holds private / acts outward). If all three are `yes` for a single LLM agent, write an explicit note in `docs/SECURITY.md` and `docs/requirements.md` that the lethal trifecta is present and must be broken (split the agent, drop a capability, or gate the action behind a human).

6. **Codex reviewer (B12).** Two separate placeholders (one value each, so plain string-replace stays correct): `{{CODEX_REVIEW_STEP}}` in `.claude/agents/code-reviewer.md`, and `{{CODEX_ROSTER_NOTE}}` in the `<agent-roster>` of `AGENTS.md`.
   - If `yes`, render `{{CODEX_REVIEW_STEP}}` (the code-reviewer block) as:

     ```
     ### Second opinion (Codex)

     For non-trivial or security-sensitive changes, run an independent review with the Codex CLI and reconcile its findings with your own:

     ```bash
     codex exec "Review the staged diff for correctness, security, and architecture. List concrete issues with file:line."
     ```

     Treat Codex as a peer, not an oracle: verify each finding against the code before acting on it, and note in the review where you and Codex disagreed and why. Do not block APPROVE on Codex alone; the quality gate is still the gate.
     ```

     and render `{{CODEX_ROSTER_NOTE}}` (the one-line roster note, which sits right after the `@code-reviewer` line) as: ` Runs an independent Codex second-opinion pass on important changes.`
   - If `no`, render BOTH `{{CODEX_REVIEW_STEP}}` and `{{CODEX_ROSTER_NOTE}}` as empty strings.

7. **Discovery answers (Part A).** Render EVERY Part A answer as real content --
   a generated project must not ship a TODO for anything the interview asked:
   `{{CORE_JOURNEY}}` (numbered steps), `{{SUCCESS_MEASURE}}`, `{{SUCCESS_METRICS}}`,
   `{{RISKIEST_ASSUMPTION}}`, `{{REQ_AC_LIST}}`, `{{NON_GOALS}}`, `{{OTHER_USERS}}`,
   `{{CONSTRAINT_TIME}}`, `{{CONSTRAINT_COST}}`, `{{CONSTRAINT_DATA}}`,
   `{{FIRST_MILESTONE}}`, `{{DEPLOYMENT_TARGET}}`, `{{SCALE_EXPECTATIONS}}`,
   `{{INTEGRATIONS}}`, `{{IN_SCOPE_LIST}}`, and the five positioning values
   (`{{PAIN_POINT}}`, `{{PRODUCT_CATEGORY}}`, `{{CURRENT_ALTERNATIVE}}`,
   `{{KEY_BENEFIT}}`, `{{KEY_DIFFERENTIATOR}}`). None of these may render as
   `TODO` -- if one is unknown, the interview was not finished; go back and ask.
   The only allowed TODO form is `TODO(interview-skipped)` when the user
   explicitly refused a question.

8. **Capability dependencies (B3-B6).** The manifest ships a minimal core only; append ONLY the dependencies the answers call for, using the chosen profile's `add_dep_command` (prefix Python's `uv add` with `DEPS_VETTED=1` so the deps-guard hook allows it). Map intent to packages, per language:
   - **Python** -- FastAPI: `fastapi`, `uvicorn[standard]`; Flask: `flask`; Streamlit/Gradio: `streamlit`/`gradio`; Postgres: `sqlalchemy`, `alembic`, `psycopg[binary]`; SQLite/DuckDB: `sqlalchemy`/`duckdb`; vectors: `pgvector`/`chromadb`/`pinecone-client`/`qdrant-client`; LLM: `openai` (also OpenRouter)/`anthropic`/`google-genai`; `httpx` for outbound HTTP.
   - **TypeScript** -- API: `express` or `fastify` (+ `@types/*`); Postgres: `pg`+`@types/pg` or `drizzle-orm`; vectors: `chromadb`/`@pinecone-database/pinecone`/`@qdrant/js-client-rest`; LLM: `openai`/`@anthropic-ai/sdk`/`@google/genai`; config validation: `zod`. Frontend frameworks (React/Next/Vue) per the user's choice.
   - **Go** -- HTTP: stdlib `net/http` (no dep) or `chi`/`gin`; Postgres: `github.com/jackc/pgx/v5`; LLM: the provider's official Go SDK or `net/http`. Add via `go get`.
   Choose the smallest set that covers the answers; do not add a database/vector/LLM dep the project did not ask for.

9. **End-to-end browser install (B2).** `.github/workflows/qa.yml` carries
   `{{E2E_BROWSER_INSTALL_STEP}}` at 6-space indent inside the e2e job. Render it:
   - UI project (B2 `yes-spa`/`yes-minimal`) AND the profile defines
     `e2e_browser_install`:
     ```
     - name: Install browsers
       run: <e2e_browser_install value>
     ```
     (multi-line: re-indent per the multi-line rule above).
   - Otherwise (API-only, or no browser install for the profile): render exactly
     `# no browser needed for this project's e2e suite`.
   Never leave the placeholder or a commented stub behind.

After all files are written:

1. Create the `CLAUDE.md` symlink: `ln -s AGENTS.md CLAUDE.md`
   - On Windows without WSL, instead create `CLAUDE.md` as a one-line pointer: `# See @AGENTS.md`
2. Make scripts executable: `chmod +x .claude/hooks/*.sh` and, if the profile ships shell runners (Python, Go), `chmod +x scripts/*.sh`. (TypeScript runs the gate via npm scripts, so it has no `scripts/*.sh`.)
3. Confirm the template version stamp exists at `.claude/.template-version` (the bootstrap `install.sh` writes the pinned ref there). If it is missing -- e.g. the project was set up by hand rather than via `install.sh` -- create it: `printf '%s\n' "v1.1.4" > .claude/.template-version`, using the version this skill copy was installed from. The upgrade skill treats a missing stamp as "unknown, reconcile fully."
4. Delete the temp file: `rm docs/_init-answers.md`

### Phase 4.5: Install dependencies

If `{{USES_DEVCONTAINER}}` is `no`:

1. Verify the chosen package manager is available (the bootstrap should have caught this for known languages; verify again here for safety).
2. Run `{{INSTALL_COMMAND}}` to install deps from the manifest file.
3. Smoke-test:
   - Python: `uv run python -c "import sys; print(f'Python {sys.version.split()[0]} venv ready')"`
   - TypeScript: `node -e "console.log('Node ' + process.version + ' ready')"`
   - Rust: `cargo --version`
   - Go: `go version`
4. If install fails, leave the scaffold in place (do not roll back). Report the failing dep and ask the user to fix the manifest then re-run install.

If `{{USES_DEVCONTAINER}}` is `yes`: **skip** this phase. Deps will install inside the container.

### Phase 5: Verify and report

First, confirm the **core** files (every project, every language) exist:

```bash
test -f AGENTS.md && test -L CLAUDE.md && test -f README.md && test -f .env.example && \
test -f .mcp.json && test -d .claude/agents && \
test -f .claude/agents/security-reviewer.md && test -f .claude/agents/tech-debt.md && \
test -f .claude/settings.json && test -f .claude/hooks/deps-guard.sh && \
test -f .github/workflows/qa.yml && test -f .github/pull_request_template.md && \
test -d docs && test -f docs/PRODUCT_VISION.md && test -f docs/SECURITY.md && \
test -f docs/language-standards.md
```

Then confirm the chosen profile landed: its manifest (`{{MANIFEST_FILE}}`) exists, and the green-scaffold source + test exist (Python `src/example.py`+`tests/test_example.py`; TypeScript `src/example.ts`+`tests/example.test.ts`; Go `greet.go`+`greet_test.go`).

Then check no unresolved placeholders remain:

```bash
! grep -rn '{{[A-Z0-9_]*}}' . --include='*.md' --include='*.txt' --include='*.toml' --include='*.yml' --include='*.yaml' --include='*.json' --include='*.sh' --include='*.py' --include='*.ts' --include='*.go' --include='*.mod' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv 2>/dev/null
```

Finally, **run the quality gate** (inside the dev container if one is used): `{{QA_COMMAND}}`. Every complete profile ships a green-on-first-run scaffold, so the gate must pass on the first run. If it is not green, fix the scaffold before handing off -- a project that starts red is a bug.

Report what was generated, then hand off:

> "Bootstrap complete. Your project is ready. Next steps:
> 1. {{If dev container}}: Reopen in dev container, then run `{{INSTALL_COMMAND}}` inside. {{Else}}: Deps are already installed; `{{QA_COMMAND}}` is green on the fresh scaffold. Use `{{FIX_COMMAND}}` to auto-format locally.
> 2. Initialize git: `git add . && git commit -m 'chore: bootstrap project'`. Push to enable CI.
> 3. Restart Claude Code so `.mcp.json` (Context7) registers.
> 4. Start your first task -- replace `src/example.py` and `tests/test_example.py` with your first slice."

---

## Placeholder substitution

Templates use `{{PLACEHOLDER}}` syntax. Substitute these before writing.

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
| `{{E2E_BROWSER_INSTALL_STEP}}` | Derived from B2 + profile (see Phase 4 rule 9) |
| `{{LANGUAGE}}` | B1 |
| `{{HAS_FRONTEND}}` | B2 |
| `{{BACKEND_FRAMEWORK}}` | B3 |
| `{{AI_FEATURES}}` | B4 (comma-separated) |
| `{{VECTOR_DB}}` | B4 |
| `{{LLM_PROVIDER}}` | B5 |
| `{{EMBEDDINGS_MODEL}}` | B5 |
| `{{DATABASE}}` | B6 |
| `{{USES_DEVCONTAINER}}` | B7 (`yes`/`no`) |
| `{{POSITIVE_REFERENCE_TEXT}}` | A10 -- rendered line (see Phase 4) |
| `{{NEGATIVE_REFERENCE_TEXT}}` | A10 -- rendered line, may be empty |
| `{{GENERATE_EXPLANATIONS}}` | B9 (`yes`/`no`) |
| `{{SEED_GOTCHAS}}` | B10 (`yes`/`no`) |
| `{{USE_MEM0}}` | B11 (`yes`/`no`) |
| `{{MEMORY_DOC_LINE}}` | Derived from B11 (see Phase 4) |
| `{{AI_DISCIPLINE_BLOCK}}` | Derived from B4 (see Phase 4) |
| `{{CODEX_REVIEW_STEP}}` | Derived from B12 -- the review-step block in `code-reviewer.md` (see Phase 4) |
| `{{CODEX_ROSTER_NOTE}}` | Derived from B12 -- the one-line roster note in `AGENTS.md` (see Phase 4) |
| `{{DATE}}` | today, ISO format |

B8 (security profile) has no placeholder: it conditionally prunes the AI sections of `docs/SECURITY.md` and seeds the threat model (Phase 4 rule 5).

### Language-derived placeholders (from the profile)

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
    uses: astral-sh/setup-uv@v5
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
    This profile ships `.pre-commit-config.yaml` with `ruff` (`--fix`) and `ruff-format`, plus the generic hooks (trailing-whitespace, yaml/toml/json validation, large-file guard). Install once with `uv run pre-commit install`. (TypeScript and Go profiles ship no pre-commit; their `qa` gate + CI are the enforcement.)
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
    uses: actions/setup-node@v4
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
test_command: "go test ./..."
lint_tool: "golangci-lint"
lint_command: "golangci-lint run"
format_tool: "gofmt"
format_command: "gofmt -l ."   # CHECK form (lists unformatted files); fix.sh does -w
type_tool: "go build"
type_command: "go build ./..."
precommit_install_command: ""   # Go profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Go
    uses: actions/setup-go@v5
    with:
      go-version: "1.25"
      cache: true
  - name: Download modules
    run: go mod download
  - name: Install golangci-lint
    run: |
      curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b "$(go env GOPATH)/bin" v2.12.2
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

### Experimental languages (Rust, Other)

Rust and "Other" have **no profile yet** -- there is no `templates/profiles/rust/` to copy, so a generated project would be core-only with no working toolchain. Do not imply otherwise. Get explicit consent first:

> "Heads up: Rust isn't a built profile yet. I can lay down the universal core (AGENTS.md, docs, security files, CI shape), but you'd have to build the toolchain yourself -- there's no validated manifest, lint/format/type setup, qa/fix scripts, or green scaffold -- so the first quality-gate run won't pass until you complete it. Proceed on that basis, switch to Python/TypeScript/Go, or have me add a Rust profile properly first?"

If they proceed, copy `templates/core/` only, leave clearly-marked TODOs in `docs/language-standards.md` and `.github/workflows/qa.yml`, do NOT generate a manifest or scripts, and tell them the gate is not green until they finish the toolchain. The better path is to add a real profile under `templates/profiles/rust/` (see the repo `AGENTS.md` `<adding-a-language-profile>`) so the experience matches Python/TS/Go.

---

## Failure modes and how to handle them

**The user can't decide on a language.**
Python, TypeScript, and Go are all complete profiles; default to Python if there is no other signal. Don't let analysis paralysis block progress.

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
