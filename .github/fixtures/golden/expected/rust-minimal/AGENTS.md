<!-- FW-BLOCK: development-process v2.0.0 -->
<development-process>
- Dev container: no. If yes, all commands run inside the container: do not install anything globally on the host.
- Orient once per session: the main-context driver reads `docs/structure.txt` and `docs/requirements.md` at session start, and `docs/SECURITY.md` for any task touching auth, input handling, external content, or tools. Subagents do NOT re-read the full doc set -- each dispatch brief names the exact docs that task needs (see `<token-discipline>`).
- Always consult `docs/documentation.md` for links to library docs. Prefer Context7 (see below) for live API lookups.
- If you encounter unfamiliar libraries, APIs, or patterns, research online before guessing. Fetch the actual documentation. Never write library code from training memory: API names and signatures drift, and guessed names are how hallucinated/typosquatted imports get in.
- Work in this directory/repo only. Never touch files outside this repo unless explicitly instructed.
- It is your responsibility to manage the environment and install any new dependencies as needed. The package-manager and install commands for this project are recorded in `docs/language-standards.md`. New dependencies pass through the supply-chain guard hook (see `<quality-gate>`).
- The bundled quality-gate command is `bash scripts/qa.sh` (runs lint + format + types + unit/functional tests in order). It is wired into the QA hook and the CI workflow. Do not bypass it. End-to-end tests run separately (slower) in CI; see `<test-discipline>`.
</development-process>
<!-- /FW-BLOCK: development-process -->

<!-- FW-BLOCK: architecture-discipline v2.0.0 -->
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
<!-- /FW-BLOCK: architecture-discipline -->

<!-- FW-BLOCK: security-discipline v2.1.0 -->
<security-discipline>
These rules are universal: they hold for any stack and any subject. The threat model, the concrete per-stack defenses, and the red-team checklist live in `docs/SECURITY.md` -- read it for any task touching auth, input, external content, or tools.

- **Trust no input.** Treat every external input as hostile until validated: request bodies and params, uploaded files, web/tool/MCP results, and any LLM output. Validate at the boundary, not at the point of use, and against a strict format allowlist (an exact pattern) rather than a lenient parser -- lenient parsers silently accept unexpected encodings that slip past gates.
- **Never trust user-supplied identity.** Derive the acting user from a verified session or signed token (verify the signature, don't just decode it), checked in one middleware layer, not from an id in the request body and not re-checked ad hoc per route. This is the single most common real vulnerability (broken access control / IDOR).
- **Least privilege, limit blast radius.** Scope every tool, query, and file path to the current owner. A successful attacker -- or a compromised agent -- must not be able to reach another owner's data even technically. Validate and sandbox any path or id that arrives from input (no `../` escapes).
- **Bound inputs and outputs.** Length-limit anything that flows into a prompt, a log, or storage.
- **Secrets stay out of the repo.** Keep them in env or a secret store, never in source, prompts, or committed config; the ignore file must exclude them.
- **Supply chain is not trusted by default.** Install from lockfiles only; no blind updates; confirm every new dependency is the real, established package, not a hallucinated lookalike. The `deps-guard` hook is a best-effort reminder (see `<quality-gate>`); the real controls are committed lockfiles, reviewed updates, and CI dependency scanning.
- **Fail closed.** On any security-check error or ambiguity, refuse rather than proceed.
- **The threat model stays current.** Any slice matching the canonical security trigger (see `<delivery-evidence>`) either updates `docs/SECURITY.md` for the new surface or records `Security doc delta: none, because ...` in its design memo. A reviewer who finds the threat model stale for the change blocks the ship -- documented defenses for a surface that no longer exists are worse than none.
- **Security lives in hooks and tests, not in prose.** Prompt-level "be careful" is theater. The real controls are the deps-guard hook, the access-control middleware, and the red-team tests in the suite. If this project uses LLMs or agents, the prompt-injection and lethal-trifecta rules are in `<ai-discipline>` and `docs/SECURITY.md`.
</security-discipline>
<!-- /FW-BLOCK: security-discipline -->

<!-- FW-BLOCK: investigation-discipline v2.1.0 -->
<investigation-discipline>
Prose gets a gate too: code has TDD, decisions have this block. No feature code -- not even Red-phase tests -- until this gate is passed for the slice.

- **Reality probe: fixtures come from observed reality.** Before building on any external collaborator (library, API, service, protocol, data source) or pinning any interface, make at least one REAL observation of it: a real call, a real dispatch, a real run. Record the observed request and response in `docs/probes/<slice>-<name>.md`. Test fixtures and fakes may only be authored from a recorded probe -- never from documentation, a README claim, a sibling endpoint, or memory. A fixture built from a description of endpoint A does not verify endpoint B.
- **Spike before committing to an unknown.** If the slice contains a question the codebase or a probe cannot answer, run a bounded spike first (`experiments/`, no TDD -- see `<exceptional-cases>`) and put its verdict in the design memo. A spike that surfaces red flags cannot conclude "assumptions hold": every red flag gets a written mitigation or an explicit user acceptance.
- **Design memo -- the hard gate.** Every non-trivial slice starts with a memo at `docs/designs/<slice>.md`: the problem; 2-3 candidate approaches with trade-offs; the chosen approach and why; the riskiest assumption and the probe/spike result that de-risks it; the test plan (unit / functional / e2e / security, plus the live smoke check when the suite is fake-only); and every floor heading from `<planning-discipline>`. One page is the target; when the floor headings and the page target conflict, completeness wins. **The user must approve the memo -- an `Approved: <date>` line at the top -- before any feature code is written.** Commit the approved memo (and probes) BEFORE the Red suite, so the gate order is provable from history (see `<delivery-evidence>`). "Non-trivial" is anything beyond the trivial list in `<exceptional-cases>`.
- **Live smoke check pairs with every fake-only suite.** If a slice's tests run entirely against fakes, its acceptance criteria must include one scripted check against the real system (real server boot, real endpoint hit, real tool dispatch), and the ship record links its output. Green fakes alone do not ship. Security-control proofs must exercise the real enforcement path with the live path's flags -- never an introspection endpoint that resolves policy with different defaults.
- **UI slices additionally need an approved mockup** before the memo is approved (see `<design-discipline>`).
</investigation-discipline>
<!-- /FW-BLOCK: investigation-discipline -->

<!-- FW-BLOCK: token-discipline v2.5.0 -->
<token-discipline>
Tokens are budget. Analysis is meticulous; everything else is lean. (The code-minimization ladder is adapted from Ponytail -- github.com/DietrichGebert/ponytail.)

- **Terse by default.** Working output -- status updates, inter-agent briefs, review notes -- is compressed: drop filler, pleasantries, and hedging; fragments are fine; technical terms stay exact; code and errors are quoted exactly. Full prose is reserved for design memos, security warnings, irreversible-action confirmations, and user-facing docs.
- **Lean compresses wording, never gates.** No lean, terse, no-pause, or goal-style directive waives a memo floor heading, a mandatory reviewer, or an approval gate. When such a directive is active and a human gate is reached, park the slice and report instead of skipping or self-approving (see `<loop-discipline>`).
- **The ladder -- walk it before writing any new code:** does this need to exist at all -> is it already in this codebase -> does the stdlib do it -> does the platform or framework do it -> does an installed dependency do it -> is it one line -> only then write the minimum that works. Lazy about solutions, meticulous about analysis: the ladder never replaces the probe or spike, it follows them.
- **Fix-round circuit breaker.** Maximum two fix-rounds per review finding. A third failure means the design was wrong: STOP, reopen the design memo (`docs/designs/<slice>.md`) with the user, and do not iterate further on code. After the single full review, the main context MAY apply narrowly scoped fixes to named findings directly (run only the affected checks, then the gate) -- but a fix that expands scope, changes a design decision, or touches a new surface goes back through `@implementer`. Record the total fix-round count in the ship record (see `<delivery-evidence>`).
- **One review round by default.** `@code-reviewer` runs once per slice. Re-review only the specific findings from that round; a full re-review happens only after the circuit breaker sent the slice back to design.
- **Scoped reads.** The main-context driver reads the doc set once per session; every subagent dispatch brief names exactly the docs and sections that task needs, and the subagent reads only those. Briefs live in `docs/current-task/task.md`, not re-narrated per hop.
- **Model economics -- cheapest model that clears the quality bar.** Every subagent dispatch AND every external-model call the workflow makes (a second-opinion reviewer, an evaluator, a one-off analysis) states its model -- and reasoning tier, where the tool has one -- explicitly, chosen by the job, not by habit: cheapest tier for mechanical work (doc formatting, log filtering, boilerplate, status summaries); default tier for normal implementation, tests, and review; strongest tier ONLY for work where a wrong answer is expensive -- auth, payments, data deletion, concurrency, genuinely hard architecture -- or where two cheaper attempts already failed. Escalate on evidence, not anxiety; downgrade experiments are cheap, so try the cheaper tier first when unsure. Cap external second-opinion calls at two rounds per slice. (If this project's own code calls model APIs, the product-side version of this rule lives in `<ai-discipline>`.)
- **Mechanical work goes to `@utility`.** Multi-step judgment-free chores -- git housekeeping, log mining/filtering, bulk renames, doc formatting, status summaries -- are dispatched to `@utility` (haiku default), never done in the main context and never sent to a default-or-stronger tier. One-off short commands stay inline; the threshold is "would this chore take more than a couple of tool calls."
- **Session-limit workload shifting.** The roster in `docs/agents.json` says where heavy work can go. When the harness shows usage-limit warnings, or a task is heavy batch work (broad audits, big migrations, long test-fix loops), dispatch it to an installed `heavy_batch` agent from the roster (e.g. `codex exec "<brief>"`) and keep the primary agent as orchestrator/reviewer -- shifting progressively more work over as limit pressure grows. There is no quota API: the triggers are the harness's own warnings and the user's judgment. Roster changes happen via `/select-agents` or by editing `docs/agents.json` (see `docs/agents.md`).
</token-discipline>
<!-- /FW-BLOCK: token-discipline -->

<!-- FW-BLOCK: test-discipline v2.1.0 -->
<test-discipline>
TDD is the loop; this block defines the shape of the test suite each slice must produce. Write the functional and end-to-end specs at the SAME time as the unit specs -- list every test in the task plan before any code (Red phase). A slice is not "spec'd" until its e2e/functional tests are named.

- **Unit** -- pure logic, tests mirror source layout.
- **Functional / integration / API** -- exercise the real endpoint or flow against a real server harness and a real datastore (rollback per test). No mocks for code you own.
- **End-to-end** -- the user-visible flow end to end. If the project has a UI, this means a small number of **headless-browser** e2e tests (stable selectors, no implementation internals). If it is API-only, an e2e asserts the full request -> response -> persisted-state path.
- **Security / red-team** -- required when the project reads untrusted content, holds private data, or exposes auth. Driven by `docs/SECURITY.md`.

**Red lands before Green, as its own commit.** Run the new suite and verify every failure is a missing-implementation failure, then commit it before implementing. If tests and implementation were authored together and Red was only proven retroactively (stash the implementation, confirm the failures, restore), that is the exception, not the loop: the ship record marks `TDD audit: weak` with the reason (see `<delivery-evidence>`).

**The verification surface is the slice's evaluator -- changes to it are spec amendments.** Tests, fixtures, snapshots, QA-runner config, and CI workflows verify the work; the agent making tests pass must not quietly reshape them. Between the Red commit and ship, adding new tests is normal; modifying or deleting existing tests, fixtures, or gate config requires a stated reason in the review notes and the reviewer's explicit sign-off -- `@code-reviewer` diffs the verification surface Red -> Green and treats an unexplained change as a finding. Never weaken, skip, or comment out a failing test to make the gate pass.

Mocks only for external services you do not own; prefer recorded responses. The inner loop stays fast: `bash scripts/qa.sh` runs lint/format/types plus unit and functional tests. The slower **headless-browser e2e** suite runs in CI and pre-merge, not on every TDD cycle.
</test-discipline>
<!-- /FW-BLOCK: test-discipline -->

<!-- FW-BLOCK: style-references v2.0.0 -->
<style-references>
<!-- No positive reference yet. Add one to this block when you choose one. -->


When no positive reference is named (or as a baseline alongside one), apply four default rules to every file: **small and direct** (one concept per file, functions before classes); **no premature abstraction** (two real callers before extracting); **boring tech beats clever tech** (novelty in stack or pattern needs a written reason); and **plain English in everything humans read** (docs, errors, commits, comments -- if a sentence does not survive being read aloud, rewrite it). The first two restate `<architecture-discipline>`; the last two are the style baseline.

A reference can be a public repo, a deployed product, a folder on disk, screenshots, a design system, or a piece of writing -- a concrete artifact someone can open, not an abstract description. A new file should look like it could belong in the positive reference and pass the four default rules above.
</style-references>
<!-- /FW-BLOCK: style-references -->

<!-- FW-BLOCK: design-discipline v2.0.0 -->
<design-discipline>
**Trigger (canonical -- quoted verbatim wherever mockups are mentioned): any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved.** Do not settle it with an ASCII diagram or "show the UI later". Build a real mockup the user can open -- a standalone HTML page, or several variations toggleable from one route; use a `prototype`/mockup skill if one is installed -- and let the user pick from the rendered artifact. Only after the user picks does the slice enter the design memo and then TDD. Keep it throwaway.

Baseline for every mockup and UI screen, so improvised screens do not look templated:
- One type scale (a fixed ratio, e.g. 1.25) and at most two fonts; body text 16px or larger.
- One spacing unit (4px or 8px) used everywhere; align elements to a grid.
- One accent color plus neutrals; spend the accent on the primary action only.
- Layout before decoration: hierarchy, alignment, and whitespace first; styling flourishes last.
- Match the positive style reference (`<style-references>`) when one exists.
</design-discipline>
<!-- /FW-BLOCK: design-discipline -->

<!-- FW-BLOCK: global-documents v2.1.0 -->
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
- `docs/designs/` : one approved design memo per non-trivial slice -- the pre-code gate (see `<investigation-discipline>`).
- `docs/probes/` : recorded real observations of external collaborators; fixtures are authored from these.
- `docs/ships/` : one ship record per shipped slice -- the durable delivery evidence (see `<delivery-evidence>`).
</global-documents>
<!-- /FW-BLOCK: global-documents -->

<!-- FW-BLOCK: backlog-discipline v2.1.0 -->
<backlog-discipline>
Each row in `docs/backlog.md` is a vertical slice that moves a working demo forward by one observable step. End-to-end through whatever layers the project has. If a row cannot be demoed when done, cut scope until it can.

At the start of a slice, pick the row that gives the biggest user-visible step forward for the smallest amount of new code. Cut scope before adding complexity.

When a slice ships, write its ship record at `docs/ships/<slice>.md` (schema in `<delivery-evidence>`), commit it in the shipping commit, and move the row from Active to Shipped with a link to the record. The record -- not the commit message -- carries `review rounds: N, fix rounds: M` and the audit fields; squash-clean history must not hide churn from a later post-mortem. Empty the Active section enough that the next slice is obvious.

Anything off-scope that comes up during a slice goes to `docs/proposals-ideas.md` (rough idea) or as a new backlog row (clearly scoped). Not into the current slice.
</backlog-discipline>
<!-- /FW-BLOCK: backlog-discipline -->

<!-- FW-BLOCK: delivery-evidence v2.4.0 -->
<delivery-evidence>
Delivery leaves evidence a later reader can audit without transcript archaeology. Two definitions live here and are quoted verbatim wherever they are needed:

**Security trigger (canonical):** a slice is security-triggering when it adds or changes external input handling, dependence on untrusted generated output, public publishing of content, authentication or authorization, a tool or automation with side effects, or persistence of untrusted content.

**Ship record.** Every non-trivial slice gets `docs/ships/<slice>.md` before its backlog row moves to Shipped, with these fields (schema + example in `docs/ships/README.md`):

- `Task class:` standard | trivial-exception | spike
- `Memo:` link to `docs/designs/<slice>.md` + its `Approved:` date
- `Red proof:` the failing-suite run (commit or logged output) that preceded Green
- `Green proof:` the gate run that passed
- `TDD audit:` strong | weak -- weak means tests and implementation were authored together and Red was proven retroactively; give the reason
- `Evidence origin:` native | imported -- native means memo -> Red -> Green landed as separate commits in order; imported means the evidence came from a parked branch or a prior session (give the reference)
- `Reviewers:` which reviewers ran and their verdicts; security-reviewer says `not-triggered` only if the canonical trigger does not match
- `Security surface:` none | the matching trigger clause + its disposition (the `docs/SECURITY.md` delta, or `none, because ...`)
- `Review rounds: N; fix rounds: M`
- `Spec amendments:` what existing tests/fixtures/gate config changed between Red and Green, and why -- required whenever the verification surface was modified or deleted while going Green (`<test-discipline>`); the CI history check fails a native record that changed the surface without this line. Adding new tests never requires it.
- `Live smoke:` link or n/a (required when the suite is fake-only, per `<investigation-discipline>`)

**Enforcement is mechanical, not prose.** The `slice-audit.sh` hook blocks a ship commit whose staged backlog change lacks a valid ship record (see `<quality-gate>`); CI re-validates changed ship records and, for native evidence, the memo -> Red -> Green commit order. The audit runs even when no subagent was dispatched -- degraded orchestration must fail loudly, not silently.
</delivery-evidence>
<!-- /FW-BLOCK: delivery-evidence -->

<!-- FW-BLOCK: task-specific-documents v2.1.0 -->
<task-specific-documents>
- `docs/current-task/task.md` : coordination document for the active task. Shared memory between agents. Working state only -- it gets reset.
- `docs/current-task/task-template.md` : template to reset `task.md` when starting a new task.

When starting a new task, copy `task-template.md` over `task.md` and fill it in. When the task ships, the durable outcome goes to the ship record at `docs/ships/<slice>.md` (see `<delivery-evidence>`) before `task.md` is reset -- a commit message is not an archive.
</task-specific-documents>
<!-- /FW-BLOCK: task-specific-documents -->

<!-- FW-BLOCK: library-docs v2.0.0 -->
<library-docs>
This project ships with **Context7 MCP** wired up via `.mcp.json`. Context7 provides up-to-date, version-specific library documentation across languages.

**When to use it**: the FIRST time this project touches a given third-party library, and again for any version-sensitive API (signatures that shift between minor versions). Do not re-query on every edit -- record what a lookup taught you in `docs/documentation.md` and reuse it. Writing library code from training memory remains forbidden: with neither a prior lookup nor a probe on disk, look it up.

**How to use it**:
- Before writing the code, query Context7 for the relevant API of the **pinned version** in your manifest file (Cargo.toml), not the latest available.
- For frontend frameworks: look up the specific component or hook you intend to use.
- For libraries whose APIs shift between minor versions (web frameworks, validation/serialization libraries, async runtimes, LLM SDKs when in use): verify the current signature; do not write from memory.

**Rule**: do not write code from training-data memory for these libraries. If Context7 returns nothing useful for a query, say so in your summary and propose a fallback (a smaller, safer call signature, or `WebFetch` of the upstream docs).
</library-docs>
<!-- /FW-BLOCK: library-docs -->

<!-- FW-BLOCK: tools v2.0.0 -->
<tools>
- Use the project's package-manager exclusively (recorded in `docs/language-standards.md`). Never bypass it.
- Use the project's lint/format/type/test toolchain (recorded in `docs/language-standards.md`). The `bash scripts/qa.sh` script chains all of them.
- When a tool could help, use it. Prefer Context7 for library API lookups, `WebFetch` for other web docs. Use MCP tools when relevant.
</tools>
<!-- /FW-BLOCK: tools -->

<!-- FW-BLOCK: quality-gate v2.1.0 -->
<quality-gate>
The gate is deterministic and enforced by hooks, not by remembering to run it. Four layers:

1. **Static + test hook.** Before declaring any task complete, run `bash scripts/qa.sh` -- it **verifies only and changes no files** (lint, format *check*, type-check, then unit + functional tests, in order). All must pass. If a step fails, fix the cause; to auto-repair formatting/lint locally run `bash scripts/fix.sh`, review the diff, then commit. Don't skip steps. Don't comment out failing tests. The `code-reviewer`'s `Stop` hook (auto-converted to `SubagentStop`) runs `bash scripts/qa.sh` when the review completes and blocks completion (exit code 2) on failure, so APPROVE cannot ship a red build; the reviewer itself re-runs only the specific failing step it is investigating, not the whole gate. Because the gate never mutates code, it cannot silently "fix" and pass.
2. **Supply-chain guard hook (best-effort).** A `PreToolUse` hook (`.claude/hooks/deps-guard.sh`, wired in `.claude/settings.json`) blocks the common dependency-install / remote-execute Bash commands until they are vetted (re-run with `DEPS_VETTED=1` at the start). It is a heuristic speed bump, not a boundary: it does not catch installs via scripts, direct manifest edits, or novel package managers. The real controls are committed lockfiles, reviewed dependency updates, and CI vulnerability scanning (the language's audit tooling, Dependabot).
3. **CI.** CI runs the same non-mutating `bash scripts/qa.sh` plus the slower end-to-end (headless-browser) suite (see `.github/workflows/qa.yml`). Note: the shipped workflow runs on pull requests and on pushes to `main`; **merge-blocking requires enabling branch protection** on the repo (the template cannot set that for you).
4. **Ship audit.** `slice-audit.sh` (`.claude/hooks/slice-audit.sh`) is an agent-neutral CLI with two callers: a `PreToolUse` hook runs it in `--hook` mode on every `git commit` and blocks the commit if the working tree's uncommitted backlog change moves a row to Shipped without a valid, tracked `docs/ships/<slice>.md` (presence + required fields -- a speed bump on the working tree, no history archaeology locally); the CI audit job runs `--range` over the pushed range and is the authority: every newly Shipped slice must have a committed valid record, and `Evidence origin: native` must prove the memo -> Red -> Green commit order. Because both callers are plain scripts, the audit holds even when no subagent ran and regardless of which coding agent drives the session.
</quality-gate>
<!-- /FW-BLOCK: quality-gate -->

<!-- FW-BLOCK: self-improvement v2.0.0 -->
<self-improvement>
This project is designed to improve itself over time. When you finish a task:

1. If you learned a non-obvious pitfall, anti-pattern, or convention: update `docs/gotchas.md`.
2. If you changed the project layout (added a folder, moved a module): update `docs/structure.txt`.
3. If you encountered an out-of-scope improvement worth doing later: append to `docs/proposals-ideas.md`.
4. If a generic lesson emerged that would apply to OTHER projects too: flag it for the user to consider backporting to the ForgeWorks template this project was generated from.

Do not skip these. The system gets better only if these living docs stay current.
</self-improvement>
<!-- /FW-BLOCK: self-improvement -->

<!-- FW-BLOCK: agent-roster v2.5.0 -->
<agent-roster>
The main-context driver (you, in Claude Code) is the orchestrator. The upstream `tdd` and `grill-me` skills (from `mattpocock/skills`) provide the methodology; do not substitute other skill packs for them. Subagents split into a mandatory tier the orchestrator may not skip and an optional tier used when isolation pays.

**Skills (upstream, from mattpocock/skills -- keep current; pull the latest each project):**
- `tdd` : Red -> Green -> Refactor methodology. Invoke in main context when writing tests and making them pass.
- `grill-me` : structured interrogation. Invoke at the start of EVERY non-trivial slice or feature, not only the first (see `<planning-discipline>`).

**Mandatory reviewers** (dispatch is not optional; the ship record proves they ran -- see `<delivery-evidence>`):
- `@code-reviewer` : runs once per non-trivial slice. Runs the quality gate and reviews; diffs the verification surface Red -> Green (see `<test-discipline>`). Has a `Stop` hook that re-runs the gate and blocks completion on failure.
- `@security-reviewer` : runs for every slice matching the canonical security trigger (quoted from `<delivery-evidence>`): *external input handling, dependence on untrusted generated output, public publishing of content, authentication or authorization, a tool or automation with side effects, or persistence of untrusted content* -- and at least once per iteration. Folding a "security focus" into the code-reviewer brief does not satisfy this; the independent red-team pass is the point.

**Optional workers** (use when a phase is complex enough to warrant an isolated context):
- `@test-spec-writer` : writes the failing test suite (unit + functional + e2e + security) for a requirement.
- `@implementer` : makes failing tests pass, refactors, and checks the change against the full-picture architecture before handoff.
- `@tech-debt` : sweeps for accumulated debt (oversized files, duplication, dead code, stale docs) and proposes a paydown plan. Run on the cadence in `<recurring-reviews>`.
- `@utility` : haiku-pinned mechanical-chore worker (git housekeeping, log mining, bulk renames, formatting). Dispatch per the mechanical-work rule in `<token-discipline>`; it never writes product code.

**Picking a model per call**: each subagent file has a default `model:` in its frontmatter. **Always pass an explicit `model`** when dispatching a subagent -- one that inherits an unavailable model can die mid-task after many tool calls, leaving partial file changes behind. Choose the tier by the model-economics rule in `<token-discipline>`: cheapest that clears the job's quality bar; strongest only for security-sensitive or architecturally hard work.

For trivial tasks as defined in `<exceptional-cases>` (no behavioral effect): skip subagents entirely. Make the change directly, run `bash scripts/qa.sh`, commit.
</agent-roster>
<!-- /FW-BLOCK: agent-roster -->

<!-- FW-BLOCK: recurring-reviews v2.1.1 -->
<recurring-reviews>
Two reviews recur because their problems accumulate silently between features. Both are **event-triggered first** -- tied to things the ship-record audit can see -- with wall-clock scheduling only as a backstop:

- **Security red-team (`@security-reviewer`).** Trigger: every slice matching the canonical security trigger in `<delivery-evidence>` (the ship record's `Security surface:` field is the evidence it ran), and at least once per iteration regardless. Walk every external data source that can reach the system -- request bodies, uploads, web/tool/MCP results, and (if applicable) prompts -- and try to break it per the `docs/SECURITY.md` checklist. A passing test is not proof of safety; it only has to fail once.
- **Tech-debt sweep (`@tech-debt`).** Trigger: every third shipped non-trivial slice, and before any release or milestone. Find files over the line cap, real duplication (DRY paydown), dead code, and docs that drifted from the code. Produce a ranked paydown list under a dated heading in `docs/proposals-ideas.md`; fix the cheap high-value items now, schedule the rest. The dated heading is the evidence the sweep ran, and the CI ship-audit prints a non-blocking `WARN tech-debt sweep overdue` when 3+ slices are Shipped without one.

To add a wall-clock backstop, the user can wire each as a scheduled agent with `/schedule` -- offer this once the project has a stable main flow, do not assume it. A schedule supplements the event triggers; it never replaces them.
</recurring-reviews>
<!-- /FW-BLOCK: recurring-reviews -->

<!-- FW-BLOCK: loop-discipline v2.1.0 -->
<loop-discipline>
The human is a gate, not the engine: approvals batch at slice boundaries, and everything between two boundaries may run as a loop. But autonomy is granted per slice, never assumed -- and gates degrade loudly, never silently.

- **Attended is the default.** An unattended run (a goal-driven session, a scheduled routine, a directive like "keep going until done") is legitimate ONLY inside a declared **autonomy envelope** in the slice's design memo: the goal condition and how it is proven (which command, which output); allowed scope (paths it may touch) and side-effect authority (what it may write, publish, install, or spend); the verifier paths it may NOT change without a spec amendment (see `<test-discipline>`); isolation (branch or worktree); stop caps (max turns, wall-clock, or spend) plus a no-progress rule (two consecutive passes without measurable movement toward the goal = stop and report); and the escalation contact.
- **Human gates park, never convert.** Memo approval, mockup approval, publishing to the outside world, and anything `<security-discipline>` fails closed on stay human decisions in every mode. When an unattended run reaches one, it parks the slice, records where it stopped, moves to other in-envelope work or ends, and reports -- it does not self-approve, skip, or downgrade the gate.
- **A goal condition is a driver, not a verifier.** Phrase goal conditions in gate terms -- "`bash scripts/qa.sh` green, every AC's named test passing, ship record valid, or stop after N turns" -- and remember that a goal evaluator only reads what the session surfaced; the deterministic hooks, the gate command, and CI remain the authority on "done". A loop that cannot cite a gate run has not finished.
- **A loop pays only when** the work repeats, verification is automated, the budget absorbs retries, and the agent can actually run what it builds. Otherwise stay attended -- a one-off task is still better served by one good turn.
</loop-discipline>
<!-- /FW-BLOCK: loop-discipline -->

<!-- FW-BLOCK: planning-discipline v2.4.0 -->
<planning-discipline>
Planning is where most quality is won or lost. Do not be lazy here, and do not just transcribe what the user says -- interrogate it. Start from the heart of the project: the one flow that, if it works, makes the project worth building. Plan that first; everything else is a slice around it. The output of this pass is the design memo at `docs/designs/<slice>.md` (see `<investigation-discipline>`). Planning is done when the user approves the memo -- not when a test list exists.

This pass is **recurring, not once-per-project**: it runs at the start of EVERY non-trivial slice, new feature, and change cycle -- the interview at bootstrap does not exhaust it. Each pass has two movements: **brainstorm first** (divergent -- what could this be? name at least two ways to build it and pick one for a reason; use a brainstorming skill if one is installed), **then grill** (convergent -- if the `grill-me` skill from mattpocock/skills is installed, run it with the agenda below; otherwise apply the agenda directly). Do not skip questions to move faster, and do not write code before both movements are done.

**Required discovery -- the memo floor.** The plan is not done until each item below is answered in writing: worked in `docs/current-task/task.md`, final answers in the design memo. This floor survives every communication mode: a lean, terse, no-pause, or goal-style directive may compress the wording of an answer, but may not remove a heading, skip a question, or start code before the memo is approved (see `<token-discipline>`).
- **Core journey.** The exact user-visible flow this slice delivers, step by step. If it cannot be demoed when done, cut scope until it can.
- **Concrete examples.** Real input samples, expected output samples, and a file or the positive style reference to pattern-match against. Abstract specs drift from the user's taste; samples anchor them. If the user has none, ask; do not invent.
- **Riskiest assumption.** The one thing that, if wrong, sinks the slice. De-risk it with a reality probe or a bounded spike BEFORE any code (see `<investigation-discipline>`); only then plan its tests.
- **Explicit non-goals.** What this slice deliberately does NOT do. Push those to `docs/proposals-ideas.md` or a new backlog row.
- **Unhappy paths and the attacker story.** The error states, empty/edge inputs, and failure modes this slice must survive -- and, for any slice matching the canonical security trigger (see `<delivery-evidence>`), one short paragraph telling the attack as a story: who sends what, through which surface, to get what.
- **Data shapes.** The shape of the data crossing each boundary (request, response, stored record, tool I/O).
- **Acceptance criteria as a contract.** Write numbered, observable criteria (AC1, AC2, ...) and map each to the test(s) that prove it. A criterion with no test isn't testable as written; "done" means every criterion has a covering test -- gate-run tests pass under `bash scripts/qa.sh`, and an e2e-only criterion is verified present/wired (CI runs it). Name the unit, functional/API, end-to-end, and (if relevant) security tests up front, per `<test-discipline>`, in the same Red phase.
- **Security surface.** Which clause of the canonical security trigger (see `<delivery-evidence>`) this slice matches, if any, and which `docs/SECURITY.md` defense covers it -- plus the threat-model disposition (`SECURITY.md` delta or `none, because ...`, per `<security-discipline>`). Any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved (see `<design-discipline>`).
- **Autonomy envelope.** If any part of the slice will run unattended (a goal-driven session, a scheduled routine, a long autonomous directive), declare the envelope from `<loop-discipline>` in the memo. Attended-only slices write `Autonomy: attended`.

**Be proactive, not stenographic.** Before locking the plan, run one "what's missing?" pass: name the aspects the user has not mentioned (error states, empty/edge inputs, auth, scale, observability, the unhappy path) and surface them. Tell the user what you think they have not thought about. Then write the design memo and get the user's explicit approval on it before any code.

**Then scan for parallelizable work.** If the slice has two or more independent sub-tasks (different layers, different files, no shared state), propose running them as parallel background subagents. The default is sequential; parallelism is opt-in. Parallel subagents that write files share one `.git/index`: give each its own files (or a git worktree), and have each stage only its own paths and retry on `index.lock`, or commits will collide.

**One writer per branch (handoff freeze).** A branch has exactly one writer at a time. When a subagent reports its work complete, that report IS the handoff: the subagent stops pushing to the branch, and the orchestrator owns it from that moment -- late force-pushes after a completion report get lost in merges (a field-proven failure). The same rule in reverse: the orchestrator never rewrites a branch a subagent is still working on; message the agent to stop first, then take over.
</planning-discipline>
<!-- /FW-BLOCK: planning-discipline -->

<!-- FW-BLOCK: exceptional-cases v2.1.0 -->
<exceptional-cases>
**Trivial tasks**: skip subagents; make the change directly, run the quality gate, commit. Triviality is decided by behavioral impact, not diff size: trivial means typos, comment and doc wording, formatting, and config values with no behavioral effect. Anything that changes runtime behavior, user-visible output, identity or permissions, safety policy, or an external side effect is NOT trivial however small the diff -- and any instruction or policy text that steers runtime behavior is behavior, not docs: it gets at least a task note, a regression check, and the security-trigger test from `<delivery-evidence>`. (If this project has AI features, `<ai-discipline>` names prompt and persona text as exactly this kind of behavior.)

**Exploratory spikes** (research, prototyping to learn): work in a separate `experiments/` folder. No TDD required. Document findings in `docs/proposals-ideas.md`.

**Blocked tasks**: if a task gets stuck (test can't be written, requirements unclear, dependency missing), STOP and ask the user. Do not guess. Document the block in `docs/current-task/task.md`. In an unattended run, park the slice and report per `<loop-discipline>` instead of waiting.
</exceptional-cases>
<!-- /FW-BLOCK: exceptional-cases -->

<!--
Project: Chunkline
Goal: A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.
Primary user: A backend developer building document indexing who needs deterministic chunk boundaries.
Language: Rust
Frontend: no
AI features: none
Bootstrapped: 2026-07-12
-->
