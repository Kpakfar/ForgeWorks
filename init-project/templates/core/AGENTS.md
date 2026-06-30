<development-process>
- Dev container: {{USES_DEVCONTAINER}}. If yes, all commands run inside the container: do not install anything globally on the host.
- Always start by reading `docs/structure.txt` and `docs/requirements.md` in parallel to orient yourself. For any task touching auth, input handling, external content, or tools, also read `docs/SECURITY.md`.
- Always consult `docs/documentation.md` for links to library docs. Prefer Context7 (see below) for live API lookups.
- If you encounter unfamiliar libraries, APIs, or patterns, research online before guessing. Fetch the actual documentation. Never write library code from training memory: API names and signatures drift, and guessed names are how hallucinated/typosquatted imports get in.
- Work in this directory/repo only. Never touch files outside this repo unless explicitly instructed.
- It is your responsibility to manage the environment and install any new dependencies as needed. The package-manager and install commands for this project are recorded in `docs/language-standards.md`. New dependencies pass through the supply-chain guard hook (see `<quality-gate>`).
- The bundled quality-gate command is `{{QA_COMMAND}}` (runs lint + format + types + unit/functional tests in order). It is wired into the QA hook and the CI workflow. Do not bypass it. End-to-end tests run separately (slower) in CI; see `<test-discipline>`.
</development-process>

<architecture-discipline>
These rules are language- and stack-agnostic. Apply them on every file you write or modify.

- **Two-layer split by default.** A `backend/` (or equivalent) layer for domain logic and I/O, and a `frontend/` (or `app`, `ui/`) layer for user interface. Add a third layer (orchestrator, flow, controller) only when a task literally cannot be expressed without one. No speculative middle layers before there is a concrete reason for them.

- **One concept per file.** Each module owns a single concept (one I/O adapter, one transform, one route handler, one config loader, one tool, and so on). Target ~100 lines per file. Hard cap 200. Split before exceeding, not after.

- **Typed structured outputs at boundaries.** Use your language's idiomatic schema validation at module and API boundaries where a mismatch would silently corrupt state, and to capture domain models (see `docs/language-standards.md` for the chosen tool). Do NOT wrap UI state or every value that crosses an internal function boundary.

- **Session/UI state stays plain.** Initialize state with the framework's idiomatic pattern. Keep state initialization in one block at the top of the UI module. Do not introduce a state-wrapper class unless real behaviour lives on it.

- **No premature abstraction.** Three similar lines are better than a class with a strategy pattern. The bar for adding an abstraction is "two real callers, not one hypothetical one."

- **DRY, but bounded.** DRY and TDD run together: it is a refactor-step activity, not an up-front one. Once a rule, guard, shape, or block genuinely repeats across two or more real callers, extract it to one home, test it once, and let callers trust it (the "validate the id in one guard, every route calls it" pattern). Do not pre-extract on the first occurrence, and do not deduplicate things that merely look alike but mean different things.

- **Functions over classes.** Prefer plain functions taking simple types and returning them. Reach for a class only when state genuinely lives on the object across method calls.

- **Concrete over generic.** A function that does one specific thing well is better than a function that takes a config dict and dispatches. If you find yourself writing `if mode == "X": ... elif mode == "Y": ...`, consider whether you actually want two separate functions.

The test for any new module: a competent peer reading it for the first time should understand it in under one minute.
</architecture-discipline>
{{AI_DISCIPLINE_BLOCK}}
<security-discipline>
These rules are universal: they hold for any stack and any subject. The threat model, the concrete per-stack defenses, and the red-team checklist live in `docs/SECURITY.md` -- read it for any task touching auth, input, external content, or tools.

- **Trust no input.** Treat every external input as hostile until validated: request bodies and params, uploaded files, web/tool/MCP results, and any LLM output. Validate at the boundary, not at the point of use, and against a strict format allowlist (an exact pattern) rather than a lenient parser -- lenient parsers silently accept unexpected encodings that slip past gates.
- **Never trust user-supplied identity.** Derive the acting user from a verified session or signed token (verify the signature, don't just decode it), checked in one middleware layer, not from an id in the request body and not re-checked ad hoc per route. This is the single most common real vulnerability (broken access control / IDOR).
- **Least privilege, limit blast radius.** Scope every tool, query, and file path to the current owner. A successful attacker -- or a compromised agent -- must not be able to reach another owner's data even technically. Validate and sandbox any path or id that arrives from input (no `../` escapes).
- **Bound inputs and outputs.** Length-limit anything that flows into a prompt, a log, or storage.
- **Secrets stay out of the repo.** Keep them in env or a secret store, never in source, prompts, or committed config; the ignore file must exclude them.
- **Supply chain is not trusted by default.** Install from lockfiles only; no blind updates; confirm every new dependency is the real, established package, not a hallucinated lookalike. The `deps-guard` hook is a best-effort reminder (see `<quality-gate>`); the real controls are committed lockfiles, reviewed updates, and CI vulnerability scanning.
- **Fail closed.** On any security-check error or ambiguity, refuse rather than proceed.
- **Security lives in hooks and tests, not in prose.** Prompt-level "be careful" is theater. The real controls are the deps-guard hook, the access-control middleware, and the red-team tests in the suite. If this project uses LLMs or agents, the prompt-injection and lethal-trifecta rules are in `<ai-discipline>` and `docs/SECURITY.md`.
</security-discipline>

<test-discipline>
TDD is the loop; this block defines the shape of the test suite each slice must produce. Write the functional and end-to-end specs at the SAME time as the unit specs -- list every test in the task plan before any code (Red phase). A slice is not "spec'd" until its e2e/functional tests are named.

- **Unit** -- pure logic, tests mirror source layout.
- **Functional / integration / API** -- exercise the real endpoint or flow against a real server harness and a real datastore (rollback per test). No mocks for code you own.
- **End-to-end** -- the user-visible flow end to end. If the project has a UI, this means a small number of **headless-browser** e2e tests (stable selectors, no implementation internals). If it is API-only, an e2e asserts the full request -> response -> persisted-state path.
- **Security / red-team** -- required when the project reads untrusted content, holds private data, or exposes auth. Driven by `docs/SECURITY.md`.

Mocks only for external services you do not own; prefer recorded responses. The inner loop stays fast: `{{QA_COMMAND}}` runs lint/format/types plus unit and functional tests. The slower **headless-browser e2e** suite runs in CI and pre-merge, not on every TDD cycle.
</test-discipline>

<style-references>
{{POSITIVE_REFERENCE_TEXT}}
{{NEGATIVE_REFERENCE_TEXT}}

When no positive reference is named (or as a baseline alongside one), apply four default rules to every file: **small and direct** (one concept per file, functions before classes); **no premature abstraction** (two real callers before extracting); **boring tech beats clever tech** (novelty in stack or pattern needs a written reason); and **plain English in everything humans read** (docs, errors, commits, comments -- if a sentence does not survive being read aloud, rewrite it). The first two restate `<architecture-discipline>`; the last two are the style baseline.

A reference can be a public repo, a deployed product, a folder on disk, screenshots, a design system, or a piece of writing -- a concrete artifact someone can open, not an abstract description. A new file should look like it could belong in the positive reference and pass the four default rules above.
</style-references>

<design-discipline>
When this project has a UI and a slice involves a significant visual or UX decision (a new screen, a layout, a primary interaction), do not settle it with an ASCII box diagram or a terminal sketch. Build a real mockup the user can look at -- a simple sketch or runnable prototype (a standalone HTML page, or several variations toggleable from one route; use a `prototype`/mockup skill if one is installed) that shows what it will actually look like, and let the user decide from the rendered artifact (for browser UIs, something they can open in a browser). Keep it throwaway: the mockup explores the design, then you build it for real under the TDD loop.
</design-discipline>

<global-documents>
- `docs/PRODUCT_VISION.md` : north star -- what we're building and why. Stable across iterations.
- `docs/structure.txt` : project map (folders, what each is for). Update when layout changes.
- `docs/requirements.md` : current iteration scope, stack, acceptance criteria. Derived from the vision; moves every sprint.
- `docs/language-standards.md` : language- and tooling-specific conventions (types, imports, async, error handling, dependency management). Filled in by `/init-project` from the answers in setup.
- `docs/documentation.md` : direct links to library docs the agent should consult. Use Context7 first.
- `docs/backlog.md` : scoped, queued vertical slices. Reviewed continuously.
- `docs/proposals-ideas.md` : out-of-scope or future ideas. Reviewed every ~2 weeks.
- `docs/gotchas.md` : known pitfalls, anti-patterns, lessons learned. Living document. Update after every task that surfaces something worth keeping.
- `docs/SECURITY.md` : threat model, the layered defenses in place, and the red-team checklist. Update when a new attack surface, tool, or external input is added.
{{MEMORY_DOC_LINE}}</global-documents>

<backlog-discipline>
Each row in `docs/backlog.md` is a vertical slice that moves a working demo forward by one observable step. End-to-end through whatever layers the project has. If a row cannot be demoed when done, cut scope until it can.

At the start of a slice, pick the row that gives the biggest user-visible step forward for the smallest amount of new code. Cut scope before adding complexity.

When a slice ships, move its row from Active to Shipped (in `backlog.md` or an archive log). Empty the Active section enough that the next slice is obvious.

Anything off-scope that comes up during a slice goes to `docs/proposals-ideas.md` (rough idea) or as a new backlog row (clearly scoped). Not into the current slice.
</backlog-discipline>

<task-specific-documents>
- `docs/current-task/task.md` : coordination document for the active task. Shared memory between agents.
- `docs/current-task/task-template.md` : template to reset `task.md` when starting a new task.

When starting a new task, copy `task-template.md` over `task.md` and fill it in. When the task is done, archive the contents (move to a project log or commit message) before resetting.
</task-specific-documents>

<library-docs>
This project ships with **Context7 MCP** wired up via `.mcp.json`. Context7 provides up-to-date, version-specific library documentation across languages.

**When to use it (always)**: any time you write or modify code that touches a third-party library. Training-data memory will be off in subtle ways, especially for fast-moving libraries.

**How to use it**:
- Before writing the code, query Context7 for the relevant API of the **pinned version** in your manifest file ({{MANIFEST_FILE}}), not the latest available.
- For frontend frameworks: look up the specific component or hook you intend to use.
- For libraries whose APIs shift between minor versions (web frameworks, validation/serialization libraries, async runtimes, LLM SDKs when in use): verify the current signature; do not write from memory.

**Rule**: do not write code from training-data memory for these libraries. If Context7 returns nothing useful for a query, say so in your summary and propose a fallback (a smaller, safer call signature, or `WebFetch` of the upstream docs).
</library-docs>

<tools>
- Use the project's package-manager exclusively (recorded in `docs/language-standards.md`). Never bypass it.
- Use the project's lint/format/type/test toolchain (recorded in `docs/language-standards.md`). The `{{QA_COMMAND}}` script chains all of them.
- When a tool could help, use it. Prefer Context7 for library API lookups, `WebFetch` for other web docs. Use MCP tools when relevant.
</tools>

<quality-gate>
The gate is deterministic and enforced by hooks, not by remembering to run it. Three layers:

1. **Static + test hook.** Before declaring any task complete, run `{{QA_COMMAND}}` -- it **verifies only and changes no files** (lint, format *check*, type-check, then unit + functional tests, in order). All must pass. If a step fails, fix the cause; to auto-repair formatting/lint locally run `{{FIX_COMMAND}}`, review the diff, then commit. Don't skip steps. Don't comment out failing tests. The `code-reviewer` subagent runs `{{QA_COMMAND}}` during review; a `Stop` hook (auto-converted to `SubagentStop`) re-runs it and blocks completion (exit code 2) on failure, so APPROVE cannot ship a red build. Because the gate never mutates code, it cannot silently "fix" and pass.
2. **Supply-chain guard hook (best-effort).** A `PreToolUse` hook (`.claude/hooks/deps-guard.sh`, wired in `.claude/settings.json`) blocks the common dependency-install / remote-execute Bash commands until they are vetted (re-run with `DEPS_VETTED=1` at the start). It is a heuristic speed bump, not a boundary: it does not catch installs via scripts, direct manifest edits, or novel package managers. The real controls are committed lockfiles, reviewed dependency updates, and CI vulnerability scanning (`npm audit`, Dependabot).
3. **CI.** CI runs the same non-mutating `{{QA_COMMAND}}` plus the slower end-to-end (headless-browser) suite (see `.github/workflows/qa.yml`). Note: the shipped workflow runs on pull requests and on pushes to `main`; **merge-blocking requires enabling branch protection** on the repo (the template cannot set that for you).
</quality-gate>

<self-improvement>
This project is designed to improve itself over time. When you finish a task:

1. If you learned a non-obvious pitfall, anti-pattern, or convention: update `docs/gotchas.md`.
2. If you changed the project layout (added a folder, moved a module): update `docs/structure.txt`.
3. If you encountered an out-of-scope improvement worth doing later: append to `docs/proposals-ideas.md`.
4. If a generic lesson emerged that would apply to OTHER projects too: flag it for the user to consider backporting to the ForgeWorks template this project was generated from.

Do not skip these. The system gets better only if these living docs stay current.
</self-improvement>

<agent-roster>
The main-context driver (you, in Claude Code) is the orchestrator. The upstream `tdd` and `grill-me` skills (from `mattpocock/skills`) provide the methodology; the subagents are escape hatches for phases that benefit from isolation. Prefer the `mattpocock/skills` for the core loop; do not substitute other skill packs for them.

**Skills (upstream, from mattpocock/skills -- keep current; pull the latest each project):**
- `tdd` : Red -> Green -> Refactor methodology. Invoke in main context when writing tests and making them pass.
- `grill-me` : structured interrogation. Invoke when planning a slice (see `<planning-discipline>`).

**Subagents** (use when a phase is complex enough to warrant an isolated context):
- `@test-spec-writer` : writes the failing test suite (unit + functional + e2e + security) for a requirement.
- `@implementer` : makes failing tests pass, refactors, and checks the change against the full-picture architecture before handoff.
- `@code-reviewer` : runs the quality gate and reviews. Has a `Stop` hook that re-runs the gate and blocks completion on failure.{{CODEX_ROSTER_NOTE}}
- `@security-reviewer` : red-teams the current attack surface against `docs/SECURITY.md`. Run on the recurring cadence and whenever a slice adds an external input, tool, or auth boundary.
- `@tech-debt` : sweeps for accumulated debt (oversized files, duplication, dead code, stale docs) and proposes a paydown plan. Run on the recurring cadence.

**Picking a model per call**: each subagent file has a default `model:` in its frontmatter. **Always pass an explicit `model`** when dispatching a subagent -- one that inherits an unavailable model can die mid-task after many tool calls, leaving partial file changes behind. Override to match cost to complexity: `haiku` for trivial reviews, `sonnet` for normal work, `opus` for security-sensitive or architecturally tricky code.

For trivial tasks (typo fix, doc edit, single-line config): skip subagents entirely. Make the change directly, run `{{QA_COMMAND}}`, commit.
</agent-roster>

<recurring-reviews>
Two reviews run on a cadence, not just per-slice, because their problems accumulate silently between features:

- **Security red-team (`@security-reviewer`).** Walk every external data source that can reach the system -- request bodies, uploads, web/tool/MCP results, and (if applicable) prompts -- and try to break it per the `docs/SECURITY.md` checklist. A passing test is not proof of safety; it only has to fail once. Run after any slice that adds an attack surface, and at least once per iteration.
- **Tech-debt sweep (`@tech-debt`).** Find files over the line cap, real duplication (DRY paydown), dead code, and docs that drifted from the code. Produce a ranked paydown list in `docs/proposals-ideas.md`; fix the cheap high-value items now, schedule the rest.

These are rituals by default: the orchestrator triggers them. To run them unattended, the user can wire each as a scheduled agent with `/schedule` -- offer this once the project has a stable main flow, do not assume it.
</recurring-reviews>

<planning-discipline>
Planning is where most quality is won or lost. Do not be lazy here, and do not just transcribe what the user says -- interrogate it. Start from the heart of the project: the one flow that, if it works, makes the project worth building. Plan that first; everything else is a slice around it.

At the start of any non-trivial slice, the main-context agent runs a planning pass BEFORE writing code, and does not skip questions to move faster. If the `grill-me` skill (from mattpocock/skills) is installed, run it with the agenda below; otherwise apply the agenda directly.

**Required discovery -- the plan is not done until each is answered (in writing, in `docs/current-task/task.md`):**
- **Core journey.** The exact user-visible flow this slice delivers, step by step. If it cannot be demoed when done, cut scope until it can.
- **Concrete examples.** Real input samples, expected output samples, and a file or the positive style reference to pattern-match against. Abstract specs drift from the user's taste; samples anchor them. If the user has none, ask; do not invent.
- **Riskiest assumption.** The one thing that, if wrong, sinks the slice. Plan to test it first.
- **Explicit non-goals.** What this slice deliberately does NOT do. Push those to `docs/proposals-ideas.md` or a new backlog row.
- **Data shapes.** The shape of the data crossing each boundary (request, response, stored record, tool I/O).
- **Acceptance criteria as a contract.** Write numbered, observable criteria (AC1, AC2, ...) and map each to the test(s) that prove it. A criterion with no test isn't testable as written; "done" means every criterion has a covering test -- gate-run tests pass under `{{QA_COMMAND}}`, and an e2e-only criterion is verified present/wired (CI runs it). Name the unit, functional/API, end-to-end, and (if relevant) security tests up front, per `<test-discipline>`, in the same Red phase.
- **Security surface.** What new external input, tool, or auth boundary this slice introduces, and which `docs/SECURITY.md` defense covers it. If the slice makes a significant visual or UX choice, the plan includes building a mockup to decide from (see `<design-discipline>`).

**Be proactive, not stenographic.** Before locking the plan, run one "what's missing?" pass: name the aspects the user has not mentioned (error states, empty/edge inputs, auth, scale, observability, the unhappy path) and surface them. Tell the user what you think they have not thought about. Then summarize the plan back and get explicit sign-off before any code.

**Then scan for parallelizable work.** If the slice has two or more independent sub-tasks (different layers, different files, no shared state), propose running them as parallel background subagents. The default is sequential; parallelism is opt-in. Parallel subagents that write files share one `.git/index`: give each its own files (or a git worktree), and have each stage only its own paths and retry on `index.lock`, or commits will collide.
</planning-discipline>

<exceptional-cases>
**Trivial tasks** (typos, doc edits, single-line fixes): skip subagents. Make the change directly, run the quality gate, commit.

**Exploratory spikes** (research, prototyping to learn): work in a separate `experiments/` folder. No TDD required. Document findings in `docs/proposals-ideas.md`.

**Blocked tasks**: if a task gets stuck (test can't be written, requirements unclear, dependency missing), STOP and ask the user. Do not guess. Document the block in `docs/current-task/task.md`.
</exceptional-cases>

<!--
Project: {{PROJECT_NAME}}
Goal: {{PROJECT_GOAL}}
Primary user: {{PRIMARY_USER}}
Language: {{LANGUAGE}}
Frontend: {{HAS_FRONTEND}}
AI features: {{AI_FEATURES}}
Bootstrapped: {{DATE}}
-->
