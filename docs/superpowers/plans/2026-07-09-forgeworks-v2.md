# ForgeWorks v2.0.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship ForgeWorks v2.0.0: a hard user-approved design gate with reality probes, distilled caveman/ponytail token discipline, a product-first interview with zero elicitable TODOs, and a one-run seamless upgrade -- per the approved spec `docs/superpowers/specs/2026-07-09-forgeworks-v2-design.md`.

**Architecture:** All changes are markdown/bash/YAML edits to the template repo: `init-project/templates/core/` (the generated constitution + docs + agents), `init-project/SKILL.md` (interview + emission), `upgrade-project/SKILL.md` (reconcile), and repo meta files. No application code. Verification = the repo's own render-smoke CI, grep assertions, then a throwaway bootstrap and a capstone upgrade dry-run.

**Tech Stack:** Markdown templates with `{{UPPER_SNAKE}}` placeholder substitution, bash, GitHub Actions, `python3 .github/scripts/render_smoke.py` as the deterministic check.

## Global Constraints

- Repo conventions (`AGENTS.md` `<conventions>`): Conventional Commits (`feat(template):`, `refactor(skill):`, `docs(readme):`), NO Co-Authored-By trailer, plain English, boring tech.
- All work on branch `feat/v2-design-first`; final delivery is a PR to `main` (touches SKILL.md Phase 4 + core AGENTS.md rule blocks -> PR is mandatory).
- Every new `{{PLACEHOLDER}}` used in any template file MUST be added to (a) the Phase 4 placeholder table in `init-project/SKILL.md` and (b) the `COMMON` dict in `.github/scripts/render_smoke.py` -- otherwise root CI fails with "leftover placeholder".
- `templates/core/` stays language-free: no toolchain names outside conditional blocks/profiles.
- Do NOT use `{{...}}` for user-fillable slots; those use `*<...>*` or literal text (repo rule).
- The AI-fence regex in render_smoke.py strips only `<!-- AI-[A-Z]+-START/END -->` pairs. Do not introduce new fence *types*; new conditional behavior goes through placeholders or existing mechanisms.
- After EVERY task that edits `templates/`, run `python3 .github/scripts/render_smoke.py` from the repo root and require `ok` for all three profiles before committing.
- Version bump to `2.0.0` and pinned-ref updates happen in Task 13 only; earlier tasks leave `v1.1.4` refs alone so partial states stay coherent.

---

### Task 1: Branch and scaffolding

**Files:** none created yet.

- [ ] **Step 1: Create the branch**

```bash
cd /Users/kpakfar/multiverse/ForgeWorks
git switch -c feat/v2-design-first
```

- [ ] **Step 2: Baseline check -- render smoke is green before we touch anything**

Run: `python3 .github/scripts/render_smoke.py`
Expected: three `ok   [<lang>] rendered clean, manifest present` lines, exit 0.

---

### Task 2: Core AGENTS.md -- `<investigation-discipline>` (the hard gate)

**Files:**
- Modify: `init-project/templates/core/AGENTS.md`

**Interfaces:**
- Produces: block `<investigation-discipline>`, paths `docs/designs/<slice>.md` and `docs/probes/<slice>-<name>.md`, the approval convention `Approved: <date>` -- consumed by Tasks 4, 5, 6, 11.

- [ ] **Step 1: Insert the new block** immediately after the closing `</security-discipline>` tag (after current line 44) and before `<test-discipline>`:

```markdown
<investigation-discipline>
Prose gets a gate too: code has TDD, decisions have this block. No feature code -- not even Red-phase tests -- until this gate is passed for the slice.

- **Reality probe: fixtures come from observed reality.** Before building on any external collaborator (library, API, service, protocol, data source) or pinning any interface, make at least one REAL observation of it: a real call, a real dispatch, a real run. Record the observed request and response in `docs/probes/<slice>-<name>.md`. Test fixtures and fakes may only be authored from a recorded probe -- never from documentation, a README claim, a sibling endpoint, or memory. A fixture built from a description of endpoint A does not verify endpoint B.
- **Spike before committing to an unknown.** If the slice contains a question the codebase or a probe cannot answer, run a bounded spike first (`experiments/`, no TDD -- see `<exceptional-cases>`) and put its verdict in the design memo. A spike that surfaces red flags cannot conclude "assumptions hold": every red flag gets a written mitigation or an explicit user acceptance.
- **Design memo -- the hard gate.** Every non-trivial slice starts with a memo at `docs/designs/<slice>.md`, one page or less: the problem; 2-3 candidate approaches with trade-offs; the chosen approach and why; the riskiest assumption and the probe/spike result that de-risks it; the test plan (unit / functional / e2e / security, plus the live smoke check when the suite is fake-only). **The user must approve the memo -- an `Approved: <date>` line at the top -- before any feature code is written.** "Non-trivial" is anything beyond the trivial list in `<exceptional-cases>`.
- **Live smoke check pairs with every fake-only suite.** If a slice's tests run entirely against fakes, its acceptance criteria must include one scripted check against the real system (real server boot, real endpoint hit, real tool dispatch), and the ship record links its output. Green fakes alone do not ship. Security-control proofs must exercise the real enforcement path with the live path's flags -- never an introspection endpoint that resolves policy with different defaults.
- **UI slices additionally need an approved mockup** before the memo is approved (see `<design-discipline>`).
</investigation-discipline>
```

- [ ] **Step 2: Rewire `<planning-discipline>` to end at the memo, not a test list.** Three edits inside the existing block (lines 165-182):

(a) Append to the opening paragraph (after "...everything else is a slice around it."):

```markdown
The output of this pass is the design memo at `docs/designs/<slice>.md` (see `<investigation-discipline>`). Planning is done when the user approves the memo -- not when a test list exists.
```

(b) Replace the riskiest-assumption bullet's last sentence `Plan to test it first.` with:

```markdown
De-risk it with a reality probe or a bounded spike BEFORE any code (see `<investigation-discipline>`); only then plan its tests.
```

(c) In the "Security surface" bullet, replace the sentence beginning `If the slice is complicated and makes a significant visual or UX choice, ...` with the canonical trigger:

```markdown
Any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved (see `<design-discipline>`).
```

(d) Replace the closing sentence of the "Be proactive" paragraph `Then summarize the plan back and get explicit sign-off before any code.` with:

```markdown
Then write the design memo and get the user's explicit approval on it before any code.
```

- [ ] **Step 3: Replace `<design-discipline>` wholesale** (current lines 66-68) with:

```markdown
<design-discipline>
**Trigger (canonical -- quoted verbatim wherever mockups are mentioned): any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved.** Do not settle it with an ASCII diagram or "show the UI later". Build a real mockup the user can open -- a standalone HTML page, or several variations toggleable from one route; use a `prototype`/mockup skill if one is installed -- and let the user pick from the rendered artifact. Only after the user picks does the slice enter the design memo and then TDD. Keep it throwaway.

Baseline for every mockup and UI screen, so improvised screens do not look templated:
- One type scale (a fixed ratio, e.g. 1.25) and at most two fonts; body text 16px or larger.
- One spacing unit (4px or 8px) used everywhere; align elements to a grid.
- One accent color plus neutrals; spend the accent on the primary action only.
- Layout before decoration: hierarchy, alignment, and whitespace first; styling flourishes last.
- Match the positive style reference (`<style-references>`) when one exists.
</design-discipline>
```

- [ ] **Step 4: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected: 3x `ok`.
Run: `grep -c "investigation-discipline" init-project/templates/core/AGENTS.md` -- expected: `2` (open + close tag).
Run: `grep -c "complicated and makes a significant" init-project/templates/core/AGENTS.md` -- expected: `0`.

```bash
git add init-project/templates/core/AGENTS.md
git commit -m "feat(template): investigation-discipline hard gate + canonical mockup trigger + visual baseline"
```

---

### Task 3: Core AGENTS.md -- `<token-discipline>` and scoped reads

**Files:**
- Modify: `init-project/templates/core/AGENTS.md`

**Interfaces:**
- Produces: block `<token-discipline>` (circuit breaker "two fix-rounds", one-review-round default, ladder) -- consumed by Tasks 6 and 11.

- [ ] **Step 1: Insert the new block** immediately after the closing `</investigation-discipline>` tag (added in Task 2):

```markdown
<token-discipline>
Tokens are budget. Analysis is meticulous; everything else is lean. (The code-minimization ladder is adapted from Ponytail -- github.com/DietrichGebert/ponytail.)

- **Terse by default.** Working output -- status updates, inter-agent briefs, review notes -- is compressed: drop filler, pleasantries, and hedging; fragments are fine; technical terms stay exact; code and errors are quoted exactly. Full prose is reserved for design memos, security warnings, irreversible-action confirmations, and user-facing docs.
- **The ladder -- walk it before writing any new code:** does this need to exist at all -> is it already in this codebase -> does the stdlib do it -> does the platform or framework do it -> does an installed dependency do it -> is it one line -> only then write the minimum that works. Lazy about solutions, meticulous about analysis: the ladder never replaces the probe or spike, it follows them.
- **Fix-round circuit breaker.** Maximum two fix-rounds per review finding. A third failure means the design was wrong: STOP, reopen the design memo (`docs/designs/<slice>.md`) with the user, and do not iterate further on code.
- **One review round by default.** `@code-reviewer` runs once per slice. Re-review only the specific findings from that round; a full re-review happens only after the circuit breaker sent the slice back to design.
- **Scoped reads.** The main-context driver reads the doc set once per session; every subagent dispatch brief names exactly the docs and sections that task needs, and the subagent reads only those. Briefs live in `docs/current-task/task.md`, not re-narrated per hop.
- **Right-sized models.** Every dispatch states a model explicitly: cheapest tier for mechanical work (memos, doc formatting), default tier for normal implementation and review, strongest tier only for slices touching auth, payments, data deletion, or genuinely hard architecture.
</token-discipline>
```

- [ ] **Step 2: Scope the read mandates in `<development-process>`.** Replace line 3 (`- Always start by reading \`docs/structure.txt\` and \`docs/requirements.md\` in parallel to orient yourself. For any task touching auth, input handling, external content, or tools, also read \`docs/SECURITY.md\`.`) with:

```markdown
- Orient once per session: the main-context driver reads `docs/structure.txt` and `docs/requirements.md` at session start, and `docs/SECURITY.md` for any task touching auth, input handling, external content, or tools. Subagents do NOT re-read the full doc set -- each dispatch brief names the exact docs that task needs (see `<token-discipline>`).
```

- [ ] **Step 3: Scope Context7 in `<library-docs>`.** Replace the `**When to use it (always)**: ...` line (current line 102) with:

```markdown
**When to use it**: the FIRST time this project touches a given third-party library, and again for any version-sensitive API (signatures that shift between minor versions). Do not re-query on every edit -- record what a lookup taught you in `docs/documentation.md` and reuse it. Writing library code from training memory remains forbidden: with neither a prior lookup nor a probe on disk, look it up.
```

- [ ] **Step 4: Rework the double gate run in `<quality-gate>` item 1.** Replace the sentence `The \`code-reviewer\` subagent runs \`{{QA_COMMAND}}\` during review; a \`Stop\` hook (auto-converted to \`SubagentStop\`) re-runs it and blocks completion (exit code 2) on failure, so APPROVE cannot ship a red build.` with:

```markdown
The `code-reviewer`'s `Stop` hook (auto-converted to `SubagentStop`) runs `{{QA_COMMAND}}` when the review completes and blocks completion (exit code 2) on failure, so APPROVE cannot ship a red build; the reviewer itself re-runs only the specific failing step it is investigating, not the whole gate.
```

- [ ] **Step 5: Ship-record rework count in `<backlog-discipline>`.** Replace the line `When a slice ships, move its row from Active to Shipped (in \`backlog.md\` or an archive log).` sentence with:

```markdown
When a slice ships, move its row from Active to Shipped (in `backlog.md` or an archive log), and stamp the ship record (commit message or log row) with `review rounds: N, fix rounds: M` -- squash-clean history must not hide churn from a later post-mortem.
```

- [ ] **Step 6: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok`.
Run: `grep -c "token-discipline" init-project/templates/core/AGENTS.md` -- expected >= 2.
Run: `grep -c "When to use it (always)" init-project/templates/core/AGENTS.md` -- expected `0`.

```bash
git add init-project/templates/core/AGENTS.md
git commit -m "feat(template): token-discipline block -- ladder, circuit breaker, scoped reads, single gate run"
```

---

### Task 4: FW-BLOCK markers on every core AGENTS.md block

**Files:**
- Modify: `init-project/templates/core/AGENTS.md`
- Modify: `AGENTS.md` (repo constitution -- register the convention)

**Interfaces:**
- Produces: marker convention `<!-- FW-BLOCK: <block-name> v2.0.0 -->` ... `<!-- /FW-BLOCK: <block-name> -->` wrapped around every `<x-discipline>`/named block -- consumed by Task 11 (deterministic grafting).

- [ ] **Step 1: Wrap each top-level block.** For EVERY top-level tag in `init-project/templates/core/AGENTS.md` (`<development-process>`, `<architecture-discipline>`, `<security-discipline>`, `<investigation-discipline>`, `<token-discipline>`, `<test-discipline>`, `<style-references>`, `<design-discipline>`, `<global-documents>`, `<backlog-discipline>`, `<task-specific-documents>`, `<library-docs>`, `<tools>`, `<quality-gate>`, `<self-improvement>`, `<agent-roster>`, `<recurring-reviews>`, `<planning-discipline>`, `<exceptional-cases>`), add a marker line directly above the opening tag and directly below the closing tag. Example for one block (repeat the pattern for all):

```markdown
<!-- FW-BLOCK: security-discipline v2.0.0 -->
<security-discipline>
...existing content unchanged...
</security-discipline>
<!-- /FW-BLOCK: security-discipline -->
```

Note: `{{AI_DISCIPLINE_BLOCK}}` is a placeholder, not a literal block -- do NOT wrap the placeholder line. Instead, in `init-project/SKILL.md` Phase 4 rule 0 (done in Task 8), the rendered `<ai-discipline>` content gets the same marker pair inside the rendered string.

- [ ] **Step 2: Register the convention in the repo constitution.** In `/Users/kpakfar/multiverse/ForgeWorks/AGENTS.md`, inside `<editing-the-template>`, add a bullet after the "Conditional content inside always-on files" bullet:

```markdown
- **FW-BLOCK markers.** Every rule block in `templates/core/AGENTS.md` is wrapped in `<!-- FW-BLOCK: <name> vX.Y.Z -->` ... `<!-- /FW-BLOCK: <name> -->` markers. They ship into generated projects and are what makes `upgrade-project`'s block grafting deterministic (absent -> insert; older version -> show side-by-side; current -> skip). When you edit a block's content, bump the version in its opening marker to the release that ships the change. New blocks get markers from day one.
```

- [ ] **Step 3: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok`.
Run: `grep -c "FW-BLOCK:" init-project/templates/core/AGENTS.md` -- expected `19` opening markers; and `grep -c "/FW-BLOCK:" init-project/templates/core/AGENTS.md` -- expected `19`.

```bash
git add init-project/templates/core/AGENTS.md AGENTS.md
git commit -m "feat(template): FW-BLOCK version markers on every constitution block for deterministic upgrades"
```

---

### Task 5: docs/designs, docs/probes, structure.txt, task-template.md

**Files:**
- Create: `init-project/templates/core/docs/designs/README.md`
- Create: `init-project/templates/core/docs/probes/README.md`
- Modify: `init-project/templates/core/docs/structure.txt`
- Modify: `init-project/templates/core/docs/current-task/task-template.md`
- Modify: `init-project/templates/core/AGENTS.md` (`<global-documents>` list)

- [ ] **Step 1: Create `docs/designs/README.md`**:

```markdown
# Design memos

One memo per non-trivial slice, at `docs/designs/<slice>.md`. This is the hard gate
from `AGENTS.md` `<investigation-discipline>`: no feature code -- not even Red-phase
tests -- until the user has approved the slice's memo.

## Format (one page or less)

```
# <slice-id> <title>
Approved: <date, written by the user or with their explicit OK -- absent means NOT approved>

## Problem
One paragraph. What user-visible step this slice delivers.

## Options
2-3 candidate approaches, one line of trade-off each. Say which one and why.

## Riskiest assumption
The one thing that sinks the slice if wrong -- and the probe/spike result that
de-risks it (link the `docs/probes/` file or the experiments/ folder).

## Test plan
Unit / functional / e2e / security tests by name. If the suite is fake-only,
name the live smoke check that pairs with it.
```

Keep memos after shipping -- they are the project's decision record.
```

- [ ] **Step 2: Create `docs/probes/README.md`**:

```markdown
# Reality probes

One file per observed external collaborator, at `docs/probes/<slice>-<name>.md`.
Required by `AGENTS.md` `<investigation-discipline>`: before building on any
library, API, service, protocol, or data source, observe it for real -- one real
call, real dispatch, or real run -- and record what actually came back.

## Format

```
# <slice-id> probe: <collaborator>
Date: <date>
How observed: <the exact command / call / script used>

## Request (as sent)
<verbatim>

## Response (as observed)
<verbatim, trimmed to the relevant shape>

## Verdict
What this confirms or kills. Red flags, if any, each with a mitigation or an
explicit user acceptance.
```

Fixtures and fakes are authored FROM these files -- never from docs, README
claims, a sibling endpoint, or memory.
```

- [ ] **Step 3: Update `structure.txt`.** After the line `docs/current-task/task-template.md # template; copy over task.md when starting a new task` add:

```
docs/designs/                      # one design memo per non-trivial slice (the pre-code gate)
docs/probes/                       # recorded real observations of external collaborators
```

- [ ] **Step 4: Update `<global-documents>` in core AGENTS.md.** After the `docs/SECURITY.md` line add:

```markdown
- `docs/designs/` : one approved design memo per non-trivial slice -- the pre-code gate (see `<investigation-discipline>`).
- `docs/probes/` : recorded real observations of external collaborators; fixtures are authored from these.
```

- [ ] **Step 5: Update `task-template.md`.** Three edits:

(a) In the `## Plan` section, replace the bullet `- **Riskiest assumption (test this first):**` with:

```markdown
- **Design memo (path + `Approved:` date -- REQUIRED before any code, see <investigation-discipline>):**
- **Riskiest assumption (de-risked by which probe/spike):**
- **Reality probes (docs/probes/ files this slice's fixtures are authored from):**
```

(b) Replace the mockup bullet `- **Mockup (required BEFORE Red phase if this slice makes a significant UI/UX choice -- path/link + user approval):**` with the canonical trigger:

```markdown
- **Mockup (any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved -- path/link + approval):**
```

(c) In the test-plan section, after the `- [ ] Security / red-team ...` line add:

```markdown
- [ ] Live smoke check (required when the suite above is fake-only -- the one scripted real-system check):
```

- [ ] **Step 6: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok`.
Run: `test -f init-project/templates/core/docs/designs/README.md && test -f init-project/templates/core/docs/probes/README.md && echo ok` -- expected `ok`.

```bash
git add init-project/templates/core/docs init-project/templates/core/AGENTS.md
git commit -m "feat(template): docs/designs + docs/probes with memo/probe formats; task template gates"
```

---

### Task 6: Subagent updates (implementer, code-reviewer, security-reviewer, test-spec-writer)

**Files:**
- Modify: `init-project/templates/core/.claude/agents/implementer.md`
- Modify: `init-project/templates/core/.claude/agents/code-reviewer.md`
- Modify: `init-project/templates/core/.claude/agents/security-reviewer.md`
- Modify: `init-project/templates/core/.claude/agents/test-spec-writer.md`

**Interfaces:**
- Consumes: `docs/designs/<slice>.md` + `Approved:` convention (Task 2), circuit breaker + one-round default (Task 3).

- [ ] **Step 1: implementer.md.** Replace the whole `## Before writing code` section (lines 19-25) with:

```markdown
## Gate check (do this first, refuse if it fails)

Confirm the slice's design memo exists at `docs/designs/<slice>.md` AND carries an `Approved: <date>` line. If it is missing or unapproved, STOP: return the task stating "no approved design memo for this slice" -- do not write any code, including tests. Trivial tasks per `AGENTS.md` `<exceptional-cases>` are exempt.

## Before writing code

- Read `docs/current-task/task.md` -- the brief names the exact docs and sections this task needs (see `AGENTS.md` `<token-discipline>`); read those and `docs/language-standards.md`. Do not re-read the full doc set.
- Read the slice's design memo and any `docs/probes/` files it cites.
- Confirm the target tests exist and are failing for the right reason by running the project's test command (see `docs/language-standards.md`).
```

- [ ] **Step 2: code-reviewer.md.** Three edits:

(a) Replace pillar 0 (`0. **Static checks**: You are responsible for running the quality gate ...`) with:

```markdown
0. **Static checks**: the `Stop` hook runs `{{QA_COMMAND}}` when your review completes and blocks completion on failure -- do not run the full gate yourself as a separate pass. Re-run only the specific step you are investigating (a single failing test, one lint rule). All steps must pass for the review to complete.
```

(b) In `### Operational Context`, append a bullet:

```markdown
- **One review round by default; two fix-rounds max per finding.** After your round, the implementer gets at most two fix attempts per finding. If a finding survives both, do not request a third: mark it `DESIGN_FLAW` and state that the slice must go back to its design memo (`docs/designs/<slice>.md`) per `AGENTS.md` `<token-discipline>`.
```

(c) In `### What You Never Do`, replace `- Never APPROVE if \`{{QA_COMMAND}}\` failed. The gate is the gate.` with:

```markdown
- Never APPROVE with the gate red: your Stop hook runs `{{QA_COMMAND}}` and blocks on failure. The gate is the gate.
- Never run a third fix-round on the same finding -- escalate to `DESIGN_FLAW` instead.
```

- [ ] **Step 3: security-reviewer.md.** Change frontmatter `model: opus` to `model: sonnet`, and add to the body, after the `## Before you start` list:

```markdown
## Model sizing

This agent defaults to the standard tier. Dispatch it on the strongest available model ONLY when the slice touches auth, payments, data deletion, or a new trust boundary between agents -- match cost to blast radius (`AGENTS.md` `<token-discipline>`).

Prove controls on the enforcement path: a security check is demonstrated by exercising the REAL code path with the live path's flags and defaults -- never by an introspection or debug endpoint that resolves policy separately.
```

- [ ] **Step 4: test-spec-writer.md.** In `## Testing rules`, after the `**Always:**` list's first bullet (the "No mocks for code you own..." bullet), insert:

```markdown
- **Fixtures come from probes.** Author every fake, fixture, and recorded response from the recorded reality probe in `docs/probes/` (see `AGENTS.md` `<investigation-discipline>`). If the slice touches an external collaborator and no probe file exists, STOP and return the task: the design gate was skipped. Never derive a fixture from documentation or a sibling endpoint.
```

Also replace its `## Before writing` first two bullets with scoped reads:

```markdown
- Read `docs/current-task/task.md` -- the brief names the docs this task needs -- plus the slice's design memo (`docs/designs/<slice>.md`) and cited `docs/probes/` files.
```

(keep the `structure.txt`, `language-standards.md`, and existing-tests bullets).

- [ ] **Step 5: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok`.
Run: `grep -c "model: opus" init-project/templates/core/.claude/agents/security-reviewer.md` -- expected `0`.
Run: `grep -c "Gate check" init-project/templates/core/.claude/agents/implementer.md` -- expected `1`.

```bash
git add init-project/templates/core/.claude/agents
git commit -m "feat(template): subagents enforce the design gate, scoped reads, circuit breaker, right-sized models"
```

---

### Task 7: Interview redesign (init-project/SKILL.md Phase 2 + Phase 3)

**Files:**
- Modify: `init-project/SKILL.md` (Phase 2 questions, Phase 3 summary, "skip interview" failure mode, "After bootstrap" list)

**Interfaces:**
- Produces: question IDs A1-A10 (product) and B1-B12 (stack/opt-ins), consumed by Task 8's placeholder table and emission rules. Mapping from old numbering: Q1->A1, Q2->A2, NEW A3 (acceptance criteria), NEW A4 (non-goals), NEW A5 (constraints), NEW A6 (deployment), NEW A7 (scale), NEW A8 (integrations), NEW A9 (other users), Q10->A10, Q3->B1, Q4->B2, Q5->B3, Q6->B4, Q7->B5, Q8->B6, Q9->B7, Q14->B8, Q11->B9, Q12->B10, Q13->B11, Q15->B12.

- [ ] **Step 1: Restructure Phase 2.** Replace the section from `#### Q1. Project name and one-sentence goal` through the end of `#### Q15 ...` with two subsections. Keep the existing intro prose (the "planning interview, not a form" and "Be proactive" paragraphs) and add after them:

```markdown
The interview has two parts, in this order: **Part A -- product discovery** (the
project itself; this is where surprises are killed) and **Part B -- stack and
options** (machinery). Rule zero: **nothing this interview can elicit ships as a
TODO in the generated docs.** When an answer is vague, grill it: "How would you
verify that?", "What breaks first?", "Give me a real example input and output."
```

Part A questions (each keeps the old probing prose where the mapping says "old QN"; new questions get the text below verbatim):

- `#### A1. Project name and one-sentence goal` -- old Q1 text unchanged (including the slug derivation).
- `#### A2. The core problem, the heart, and the positioning` -- old Q2 text, PLUS this addition at the end:

```markdown
Also pin the positioning while you are here (these feed `docs/PRODUCT_VISION.md`
directly -- do not leave them for later): what CATEGORY is this product
(one noun phrase), what is the user's PAIN in one line, what is the CURRENT
ALTERNATIVE they use today, what is the KEY BENEFIT in one line, and what is the
KEY DIFFERENTIATOR versus that alternative?
```

- `#### A3. Acceptance criteria for the first iteration (NEW)`:

```markdown
Ask for 3-5 numbered, observable statements that, when all true, mean the MVP
works. These become `REQ-AC1..n` in `docs/requirements.md` -- the iteration
contract every slice cites. Probe each until it is verifiable by hand: "How
would you check this one?" Reject vague criteria ("it should be fast") and
help sharpen them ("p95 under 2s on 1k documents").
```

- `#### A4. Non-goals (NEW)`:

```markdown
What will this project deliberately NOT do in the first iteration? Get at least
two concrete non-goals. These render into `{{NON_GOALS}}` -- they are the main
defense against scope surprises.
```

- `#### A5. Constraints (NEW)`:

```markdown
- Time: deadline or cadence (sprint, hackathon, side project)? Derive the first
  milestone date if one exists.
- Cost: any budget, INCLUDING an LLM/API budget if AI features are likely?
- Data: corpus size, allowed sources, licensing constraints?
```

- `#### A6. Deployment target (NEW)`:

```markdown
Where does this run for its users -- local CLI, internal tool, public web app,
mobile, embedded? And where will it be hosted or deployed first (a laptop, a
VPS, a PaaS, on-prem)?
```

- `#### A7. Scale and performance expectations (NEW)`:

```markdown
Order of magnitude for the first iteration: how many users, requests, and how
much data? Any hard latency expectation on the core flow? "Just me, small" is a
fine answer -- but it must be recorded, not assumed.
```

- `#### A8. External systems and integrations (NEW)`:

```markdown
What existing systems, third-party APIs, or data sources must this talk to?
List each. Every one of these will need a reality probe (`docs/probes/`) before
any code builds on it -- say so now so it is not a surprise later.
```

- `#### A9. Other user segments (NEW)`:

```markdown
Besides the primary user (A1): who else might use this later? One line each;
they are recorded as deferred, not built.
```

- `#### A10. Style references` -- old Q10 text unchanged.

Part B questions -- old text unchanged except B3:

- `#### B1. Language` (old Q3), `#### B2. Frontend` (old Q4).
- `#### B3. Backend framework (if applicable)` -- replace the old Q5 body with concrete menus:

```markdown
Offer the menu for the chosen language; do not improvise:

- Python: 1) FastAPI  2) Flask  3) Streamlit/Gradio only  4) none (CLI/library)
- TypeScript: 1) Next.js  2) Express  3) Fastify  4) none (CLI/library)
- Go: 1) stdlib net/http  2) chi  3) gin  4) none (CLI/library)
```

- `#### B4. AI features` (old Q6), `#### B5. LLM provider and embeddings model` (old Q7), `#### B6. Database / persistence` (old Q8), `#### B7. Dev container?` (old Q9), `#### B8. Security profile` (old Q14), `#### B9. Per-slice explanation memos (opt-in)` (old Q11), `#### B10. Seed gotchas.md (opt-in)` (old Q12), `#### B11. mem0 (opt-in)` (old Q13), `#### B12. Codex second-opinion reviewer (opt-in)` (old Q15).

- [ ] **Step 2: Update every internal Q-number reference in SKILL.md** to the new IDs using the mapping table above. Locations: Phase 4 rules 0-9 (`Q6`->`B4`, `Q10`->`A10`, `Q11`->`B9`, `Q12`->`B10`, `Q13`->`B11`, `Q14`->`B8`, `Q15`->`B12`, `Q1-Q2`->`A1-A9`, `Q5-Q8`->`B3-B6`, `Q4`->`B2`), the placeholder-table Source column, the Phase 4 rule-5 sentence `From the setup interview (Q14)`-equivalents, and the frontmatter description if it names question counts. Verify with:

Run: `grep -n "Q1[0-5]\|Q[1-9]\b" init-project/SKILL.md` -- expected: no matches (all renumbered).

- [ ] **Step 3: Rewrite Phase 3 as a filled-docs preview.** Replace the Phase 3 block-quote summary with:

```markdown
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
```

- [ ] **Step 4: Tighten the "skip the interview" failure mode.** Replace its paragraph with:

```markdown
**The user wants to skip the interview.**
OK for Part B (stack): require only language + dev container and default the
rest. Part A cannot be fully skipped -- minimum: name, one-sentence goal, the
core flow, and at least one acceptance criterion. Explain why: every Part A
answer that is missing ships as a TODO that later becomes a surprise, which is
the exact failure this template exists to prevent. Mark whatever the user still
refuses as explicit `TODO(interview-skipped)` so it is greppable.
```

- [ ] **Step 5: Update the "After bootstrap" numbered list** (items 2-3): item 2 gets scoped-reads wording (`the main-context driver reads ... once per session; subagent briefs name the docs each task needs`), item 3 appends: `and write the design memo (docs/designs/) -- the user must approve it before any code (see <investigation-discipline>)`.

- [ ] **Step 6: Commit**

```bash
git add init-project/SKILL.md
git commit -m "feat(skill): product-first two-part interview (A1-A10/B1-B12), filled-docs preview, no elicitable TODOs"
```

---

### Task 8: Emission -- placeholder table, Phase 4 rules, render_smoke, qa.yml

**Files:**
- Modify: `init-project/SKILL.md` (placeholder table + Phase 4 rules)
- Modify: `.github/scripts/render_smoke.py` (COMMON dict)
- Modify: `init-project/templates/core/.github/workflows/qa.yml`

**Interfaces:**
- Produces: new placeholders consumed by Task 9's doc templates: `{{REQ_AC_LIST}}`, `{{OTHER_USERS}}`, `{{CONSTRAINT_TIME}}`, `{{CONSTRAINT_COST}}`, `{{CONSTRAINT_DATA}}`, `{{DEPLOYMENT_TARGET}}`, `{{SCALE_EXPECTATIONS}}`, `{{INTEGRATIONS}}`, `{{READS_UNTRUSTED}}`, `{{HOLDS_PRIVATE_DATA}}`, `{{ACTS_OUTWARD}}`, `{{PAIN_POINT}}`, `{{PRODUCT_CATEGORY}}`, `{{CURRENT_ALTERNATIVE}}`, `{{KEY_BENEFIT}}`, `{{KEY_DIFFERENTIATOR}}`, `{{FIRST_MILESTONE}}`, `{{IN_SCOPE_LIST}}`, `{{SUCCESS_METRICS}}`, `{{E2E_BROWSER_INSTALL_STEP}}`.

- [ ] **Step 1: Add rows to the universal placeholder table** in `init-project/SKILL.md`:

```markdown
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
```

Also update the existing `{{NON_GOALS}}` row's Source from `Q2/interview` to `A4` (remove the duplicate row if both exist).

- [ ] **Step 2: Extend Phase 4 rule 7 (zero elicitable TODOs).** Replace rule 7's text with:

```markdown
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
```

- [ ] **Step 3: Rewrite Phase 4 rule 9 (deterministic e2e browser step).** Replace it with:

```markdown
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
```

- [ ] **Step 4: Apply the qa.yml change.** In `init-project/templates/core/.github/workflows/qa.yml`, replace the four commented lines (`# If this project uses a headless browser ...` through `#   run: {{E2E_BROWSER_INSTALL}}`) with a single line at the same 6-space indent:

```yaml
      {{E2E_BROWSER_INSTALL_STEP}}
```

- [ ] **Step 5: Add marker wrapping to Phase 4 rule 0.** In the rendered `<ai-discipline>` block inside rule 0, add `<!-- FW-BLOCK: ai-discipline v2.0.0 -->` as its first line and `<!-- /FW-BLOCK: ai-discipline -->` as its last line (inside the rendered string, outside the `<ai-discipline>` tags). Same for rule 4's `<memory>` block: wrap with `<!-- FW-BLOCK: memory v2.0.0 -->` / `<!-- /FW-BLOCK: memory -->`.

- [ ] **Step 6: Extend render_smoke COMMON.** In `.github/scripts/render_smoke.py`, add to the `COMMON` dict:

```python
    REQ_AC_LIST="- [ ] **REQ-AC1:** x", OTHER_USERS="- x", CONSTRAINT_TIME="x",
    CONSTRAINT_COST="x", CONSTRAINT_DATA="x", FIRST_MILESTONE="x",
    DEPLOYMENT_TARGET="x", SCALE_EXPECTATIONS="x", INTEGRATIONS="- x",
    PAIN_POINT="x", PRODUCT_CATEGORY="x", CURRENT_ALTERNATIVE="x",
    KEY_BENEFIT="x", KEY_DIFFERENTIATOR="x", IN_SCOPE_LIST="- x",
    SUCCESS_METRICS="- x", READS_UNTRUSTED="no", HOLDS_PRIVATE_DATA="no",
    ACTS_OUTWARD="no", E2E_BROWSER_INSTALL_STEP="# no browser",
```

- [ ] **Step 7: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok` (will FAIL until Task 9 lands if templates are edited first; in this task order the templates still use old placeholders, so it must pass NOW -- the new COMMON keys are simply unused until Task 9).

```bash
git add init-project/SKILL.md .github/scripts/render_smoke.py init-project/templates/core/.github/workflows/qa.yml
git commit -m "feat(skill): zero-TODO emission rules, new discovery placeholders, deterministic e2e browser step"
```

---

### Task 9: Rewire requirements.md and PRODUCT_VISION.md

**Files:**
- Modify: `init-project/templates/core/docs/requirements.md`
- Modify: `init-project/templates/core/docs/PRODUCT_VISION.md`

**Interfaces:**
- Consumes: every placeholder produced in Task 8.

- [ ] **Step 1: requirements.md edits** (surgical, keep everything not listed):

(a) Replace the `Other potential users ...` block (lines 15-16) with:

```markdown
Other potential users (deferred to later iterations):
{{OTHER_USERS}}
```

(b) Replace the three `- [ ] **REQ-AC1/2/3:** TODO` lines with:

```markdown
{{REQ_AC_LIST}}
```

(c) In `## Stack`, after the `- **Dev container:** ...` line add:

```markdown
- **Deployment target:** {{DEPLOYMENT_TARGET}}
- **Scale expectations (first iteration):** {{SCALE_EXPECTATIONS}}
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
{{INTEGRATIONS}}
```

(d) Replace the three `TODO yes/no` security-profile lines with:

```markdown
- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): {{READS_UNTRUSTED}}
- **Holds private data** (user records, secrets, anything non-public): {{HOLDS_PRIVATE_DATA}}
- **Acts on the outside world** (sends, writes externally, side-effecting tools): {{ACTS_OUTWARD}}
```

(e) Replace the `## Constraints` TODO list with:

```markdown
- Time: {{CONSTRAINT_TIME}}
- Cost: {{CONSTRAINT_COST}}
- Data: {{CONSTRAINT_DATA}}
```

(f) Replace the `## Open questions` TODO bullet with:

```markdown
- none yet -- add them as they appear; resolve and move out as decisions get made
```

(g) In the AI-fenced block, replace the three `- TODO: describe ...` lines with:

```markdown
Describe the approach per feature as it is designed -- each AI feature's design
lands in its slice's design memo (`docs/designs/`), and this section links them.
```

(h) Add one line under `## Who`, replacing nothing: after the `**Primary user:** {{PRIMARY_USER}}` line the file keeps its shape; and under `## What`, no change. Finally, at the top under the title, add a pointer line:

```markdown
Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.
```

- [ ] **Step 2: PRODUCT_VISION.md** -- replace the whole file body from `## Positioning (Geoffrey Moore)` to the end with:

```markdown
## Positioning (Geoffrey Moore)

For **{{PRIMARY_USER}}**
who **{{PAIN_POINT}}**,
{{PROJECT_NAME}} is a **{{PRODUCT_CATEGORY}}**
that **{{KEY_BENEFIT}}**.
Unlike **{{CURRENT_ALTERNATIVE}}**,
we **{{KEY_DIFFERENTIATOR}}**.

## 5W answers

- **Who:** {{PRIMARY_USER}}
- **What:** {{PROJECT_GOAL}}
- **Why:** {{CORE_PROBLEM}}
- **When:** {{FIRST_MILESTONE}}
- **Where:** {{DEPLOYMENT_TARGET}}
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

{{IN_SCOPE_LIST}}

**Out of scope (non-goals)** -- what it deliberately will NOT do:

{{NON_GOALS}}

## Business goals

Outcome + metric + target. Cap at three.

{{SUCCESS_METRICS}}

## Success looks like

> {{SUCCESS_MEASURE}}

---

*Last updated: {{DATE}}*
```

- [ ] **Step 3: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py` -- expected 3x `ok` (proves every new placeholder in these files has a COMMON value from Task 8).
Run: `grep -c "TODO" init-project/templates/core/docs/requirements.md init-project/templates/core/docs/PRODUCT_VISION.md` -- expected `0` in both.

```bash
git add init-project/templates/core/docs/requirements.md init-project/templates/core/docs/PRODUCT_VISION.md
git commit -m "feat(template): requirements + vision fully wired to interview answers -- zero elicitable TODOs"
```

---

### Task 10: Python profile hardening (capstone backports)

**Files:**
- Modify: `init-project/templates/profiles/python/pyproject.toml.example`
- Modify: `init-project/SKILL.md` (Python profile `notes:`)

- [ ] **Step 1: pyproject.toml.example.** In `[tool.pytest.ini_options].addopts` add `"--import-mode=importlib",` after `"--tb=short",`. After the `[tool.ruff.lint.per-file-ignores]` table add:

```toml
[tool.ruff.lint.flake8-bugbear]
# Calls that are immutable-by-convention as parameter defaults. Extend for your
# framework (FastAPI users add: fastapi.Depends, fastapi.Query, fastapi.Body,
# fastapi.File) so B008 does not fire on idiomatic DI.
extend-immutable-calls = []
```

- [ ] **Step 2: SKILL.md Python profile notes.** In the Python profile's `notes:` YAML, append to `imports:`:

```
    - If a name is used ONLY in annotations, ruff's TC rules will move it under `if TYPE_CHECKING:` -- but a name a framework resolves at RUNTIME from the annotation (e.g. FastAPI's `Request`/`Response`/`UploadFile` in route signatures) must stay a real import. Keep those imports at runtime and mark them `# noqa: TC002` if flagged.
```

and append to `errors:` (DI rule):

```
    - Framework dependency-injection defaults (e.g. FastAPI `Depends(...)`) are called markers, not values: never replace `Depends(get_settings)` with a bare `get_settings()` call at import time -- the first form resolves per-request, the second freezes one instance at import and 500s under test overrides.
```

and append to `test_layout:`:

```
    - `--import-mode=importlib` is set in addopts: test files may share basenames across folders without `__init__.py` shims.
```

- [ ] **Step 3: Verify and commit**

Run: `python3 .github/scripts/render_smoke.py --emit python /tmp/v2py && cd /tmp/v2py && uv sync && uv run qa; cd -` -- expected: gate green (proves the toml edits parse and the scaffold still passes).

```bash
git add init-project/templates/profiles/python init-project/SKILL.md
git commit -m "feat(profile): python hardening from capstone -- importlib mode, bugbear DI defaults, TC/Depends rules"
```

---

### Task 11: upgrade-project v2 -- one run, one approval

**Files:**
- Modify: `upgrade-project/SKILL.md`

**Interfaces:**
- Consumes: FW-BLOCK markers (Task 4), new placeholders list (Task 8), `docs/designs`/`docs/probes` (Task 5).

- [ ] **Step 1: Phase 1 additions.** In `### Phase 1: Recover context`, add two detection bullets after the "AI features?" bullet:

```markdown
- **mem0 / persistent memory?** -- detect `docs/memory.md`, a `<memory>` block in `AGENTS.md`, or `mem0ai` in the manifest. If absent, ask the user once whether to add it (yes/no; default no).
- **Quality-gate command** -- recover `{{QA_COMMAND}}` from `docs/language-standards.md` (the "Quality-gate command" line) or the manifest's scripts; needed to regenerate `.claude/hooks/quality-gate.sh` if missing.
```

- [ ] **Step 2: Phase 3-A -- two new special cases.** Add to the `*Special cases:*` list:

```markdown
  - `.claude/hooks/quality-gate.sh` -- carries `{{QA_COMMAND}}`, which IS recoverable (Phase 1). If the hook is missing, substitute the recovered command and copy it; never report it as manual.
  - **Discovery placeholders (interview-sourced) in an absent file** (e.g. `{{SUCCESS_MEASURE}}`, `{{NON_GOALS}}`, `{{REQ_AC_LIST}}`, the positioning and constraints values): do NOT report "add manually" and do NOT half-write `{{...}}`. Queue the file for the Phase 3-D mini-interview.
```

- [ ] **Step 3: Phase 3-B -- deterministic marker grafting.** Replace the `**\`AGENTS.md\`** -- the high-value merge. ...` paragraph with:

```markdown
- **`AGENTS.md`** -- deterministic via FW-BLOCK markers. Since v2.0.0 every rule block in the template is wrapped in `<!-- FW-BLOCK: <name> vX.Y.Z -->` ... `<!-- /FW-BLOCK: <name> -->`. Reconcile by marker, not judgment:
  1. Parse the marker set in the template and in the project.
  2. Block absent in the project -> insert it (with its markers) at the same position it holds in the template.
  3. Block present with an OLDER marker version -> show the two versions side by side ONCE (in the Phase 4 report) and let the user choose; never silently overwrite.
  4. Block present at the current version -> skip (this is the idempotency check -- mechanical, not judgment).
  5. Project block with NO markers (pre-v2 project): match by tag name (`<security-discipline>` etc.); when matched, wrap it with markers stamped at the project's "from" version so the next run is mechanical.
  **Supersession registry** (complete -- extend on every rename):

  | Old block | Replaced by | Since |
  |---|---|---|
  | `<starting-a-slice>` | `<planning-discipline>` | v1.1.x |

  After grafting, flag any superseded block present in the project for the user to remove -- do not silently delete.
```

- [ ] **Step 4: New Phase 3-D -- the mini-interview.** Add after Phase 3-C:

```markdown
**D. Mini-interview (discovery placeholders).** Collect every queued
interview-sourced placeholder from 3-A, dedupe, and ask the user ONLY those
questions, batched in one message (use the matching Part A question wording
from `init-project/SKILL.md`). Substitute the answers and write the files.
This replaces "add manually": the upgrade ends with zero `{{...}}` on disk and
zero punted files. If the user declines a question, write
`TODO(interview-skipped)` -- never a raw placeholder.
```

- [ ] **Step 5: Phase 4 -- batched approval.** Replace Phase 4's list with:

```markdown
1. Compute the ENTIRE change set first (3-A copies, 3-B grafts, 3-C tooling
   deltas, 3-D answers). Present ONE report with five buckets: **copy verbatim**,
   **graft (new blocks, by name)**, **substitute (with the values)**,
   **needs your answer (the mini-interview questions)**, **superseded (flagged
   for removal)**. Collect the mini-interview answers and a single yes.
2. Apply everything. `chmod +x` new scripts/hooks.
3. Ensure `docs/designs/` and `docs/probes/` exist (copy their READMEs from the
   template if absent) -- they are the v2 gate's working directories.
4. Run the project's quality gate and confirm it still passes; fix any breakage
   the upgrade introduced before finishing.
5. **Only after the gate passes,** write the new version to
   `.claude/.template-version`.
6. Close with: "Upgraded <from> -> <to> in one run. Review the diff and commit
   on your branch. Nothing was overwritten without being shown first."
```

- [ ] **Step 6: Update the maintainers note** at the bottom: add that new `AGENTS.md` blocks need (a) FW-BLOCK markers in the template and (b) a supersession-registry row if they replace an old block; and that new interview-sourced placeholders must be added to the 3-A discovery list.

- [ ] **Step 7: Commit**

```bash
git add upgrade-project/SKILL.md
git commit -m "feat(skill): upgrade v2 -- marker grafting, mini-interview, quality-gate recovery, one batched approval"
```

---

### Task 12: Hygiene sweep

**Files:**
- Modify: `init-project/SKILL.md` (duplicate line; Context7 `@latest` mention; required-skills list if handoff is dead)
- Modify: `init-project/templates/core/.mcp.json`
- Modify: `AGENTS.md` (stale `e.g. 1.0.0`; register conventions)
- Possibly modify: `bootstrap/AGENTS.md` (handoff reference)

- [ ] **Step 1: Remove the duplicated Phase 5 line.** In `init-project/SKILL.md` delete the line `First, confirm the critical files exist:` (line ~369), keeping `First, confirm the **core** files (every project, every language) exist:`.

- [ ] **Step 2: Pin Context7.** Get the current version: `npm view @upstash/context7-mcp version` (record output, e.g. `1.0.X`). In `init-project/templates/core/.mcp.json` replace `"@upstash/context7-mcp@latest"` with `"@upstash/context7-mcp@<that version>"`. Also update the SKILL.md failure-modes sentence that quotes `@latest` to quote the pinned form, and strike the corresponding "not yet pinned" item from `docs/ROADMAP.md` if listed.

- [ ] **Step 3: Verify `handoff` exists.** Fetch https://github.com/mattpocock/skills (WebFetch the repo file list). If a `handoff` skill exists: no change. If NOT: remove `handoff` from the required-skills line in `init-project/SKILL.md` Phase 1 and from `bootstrap/AGENTS.md`'s list.

- [ ] **Step 4: Repo AGENTS.md touch-ups.** In `/Users/kpakfar/multiverse/ForgeWorks/AGENTS.md`: change `(e.g. \`1.0.0\`)` to `(e.g. \`2.0.0\`)`; in `<editing-the-skill>` update `Numbered Q1-Q15 today (Q14 security profile, Q15 Codex reviewer)` to `Numbered A1-A10 (product discovery) + B1-B12 (stack and opt-ins); B8 security profile, B12 Codex reviewer`; in `<editing-the-template>`'s line-cap bullet, append: `The core AGENTS.md constitution is a reference document like the SKILLs and may exceed the cap.`

- [ ] **Step 5: Verify and commit**

Run: `grep -c "confirm the critical files" init-project/SKILL.md` -- expected `0`.
Run: `grep -c "@latest" init-project/templates/core/.mcp.json` -- expected `0`.

```bash
git add init-project/SKILL.md init-project/templates/core/.mcp.json AGENTS.md docs/ROADMAP.md bootstrap/AGENTS.md
git commit -m "fix: hygiene -- dup phase-5 line, pinned context7, handoff ref verified, stale docs"
```

---

### Task 13: VERSION 2.0.0 and pinned refs

**Files:**
- Modify: `VERSION`, `bootstrap/install.sh:33`, `upgrade-project/SKILL.md` (two degit lines + prose ref), `init-project/SKILL.md` (Phase 4 stamp fallback, line ~349), `README.md:11,43`, `docs/how-to-use.md:11,20,22,42`

- [ ] **Step 1: Bump and re-pin.** Write `2.0.0` to `VERSION`. Replace every `v1.1.4` with `v2.0.0` in the files above:

```bash
grep -rln "v1\.1\.4" VERSION bootstrap/install.sh upgrade-project/SKILL.md init-project/SKILL.md README.md docs/how-to-use.md
# edit each; then verify:
grep -rn "v1\.1\.4" --include='*.md' --include='*.sh' . | grep -v docs/superpowers | grep -v portfolio-readiness
```
Expected: no remaining hits outside historical docs. (The `v2.0.0` tag will not exist until release -- that is by design; `BRANCH=feat/v2-design-first` overrides it for testing.)

- [ ] **Step 2: Commit**

```bash
git add VERSION bootstrap/install.sh upgrade-project/SKILL.md init-project/SKILL.md README.md docs/how-to-use.md
git commit -m "chore(release): bump to 2.0.0 and update pinned refs"
```

---

### Task 14: Local CI parity check

- [ ] **Step 1: Run everything root CI runs, locally**

```bash
python3 .github/scripts/render_smoke.py
bash .github/scripts/deps_guard_test.sh
while IFS= read -r f; do bash -n "$f" || echo "FAIL $f"; done < <(git ls-files '*.sh')
while IFS= read -r f; do case "$f" in */.devcontainer/*) continue;; esac; python3 -m json.tool "$f" >/dev/null || echo "bad JSON: $f"; done < <(git ls-files '*.json')
```
Expected: all green, no FAIL/bad lines.

- [ ] **Step 2: Push the branch so CI runs the three profile jobs**

```bash
git push -u origin feat/v2-design-first
gh run watch --exit-status || gh run list --branch feat/v2-design-first
```
Expected: all CI jobs green. Fix anything red before Task 15.

---

### Task 15: Throwaway bootstrap validation (spec section 10b)

- [ ] **Step 1: Bootstrap a throwaway project from the branch**

```bash
mkdir -p /tmp/forgeworks-v2-smoke && cd /tmp/forgeworks-v2-smoke && git init
BRANCH=feat/v2-design-first bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/feat/v2-design-first/bootstrap/install.sh)
```

Then open Claude Code in that directory, run `/init-project`, and walk the FULL new interview (pick Python + FastAPI + a UI answer to exercise the browser step).

- [ ] **Step 2: Assert the v2 contract on the generated tree**

```bash
cd /tmp/forgeworks-v2-smoke
! grep -rn '{{[A-Z0-9_]*}}' . --exclude-dir=.git --exclude-dir=.venv        # no placeholders
! grep -rn 'TODO' docs/requirements.md docs/PRODUCT_VISION.md               # zero elicitable TODOs
grep -c 'FW-BLOCK:' AGENTS.md                                               # >= 19 markers
grep -q 'investigation-discipline' AGENTS.md && grep -q 'token-discipline' AGENTS.md && echo blocks-ok
test -f docs/designs/README.md && test -f docs/probes/README.md && echo dirs-ok
grep -q 'Install browsers' .github/workflows/qa.yml && echo e2e-step-ok     # UI project
grep -q 'model: sonnet' .claude/agents/security-reviewer.md && echo model-ok
uv run qa                                                                    # green on first run
```
Expected: every check passes. Any failure = fix the template on the branch, re-commit, re-test.

---

### Task 16: Capstone upgrade dry-run (spec section 10c)

- [ ] **Step 1: Copy the capstone (never touch the original)**

```bash
cp -R /Users/kpakfar/multiverse/turingcollege/capstone /tmp/capstone-upgrade-dryrun
cd /tmp/capstone-upgrade-dryrun && git switch -c chore/upgrade-template
```

- [ ] **Step 2: Install the v2 upgrade skill from the branch and run it**

```bash
npx --yes degit@2.8.4 "Kpakfar/ForgeWorks/upgrade-project#feat/v2-design-first" .claude/skills/upgrade-project --force
```
Open Claude Code there, run `/upgrade-project`. NOTE: the skill's Phase 2 degit refs point at `v2.0.0` (not yet tagged) -- for the dry-run, tell the agent to reconcile against `#feat/v2-design-first` instead.

- [ ] **Step 3: Assert the seamless contract**

- ONE run completes; the mini-interview asked ONLY for genuinely missing discovery fields; a single batched approval.
- `! grep -rn '{{[A-Z0-9_]*}}' . --exclude-dir=.git --exclude-dir=.local --exclude-dir=node_modules` -- zero half-written placeholders.
- `grep -c 'FW-BLOCK:' AGENTS.md` >= 19; `docs/designs/` + `docs/probes/` exist.
- The capstone's own quality gate still passes (`uv run qa` or its documented command).
- `.claude/.template-version` reads the upgraded ref, stamped only after the gate.

Record any friction verbatim -- each item is a template fix on the branch before the PR.

- [ ] **Step 4: Clean up** -- `/tmp/capstone-upgrade-dryrun` and `/tmp/forgeworks-v2-smoke` are disposable; leave them until the PR merges in case re-checks are needed.

---

### Task 17: PR

- [ ] **Step 1: Open the PR** (required: touches Phase 4 + core AGENTS.md blocks + bootstrap-adjacent refs)

```bash
cd /Users/kpakfar/multiverse/ForgeWorks
gh pr create --title "feat: v2.0.0 -- design-first hard gate, token discipline, product-first interview, seamless upgrade" \
  --body "Implements docs/superpowers/specs/2026-07-09-forgeworks-v2-design.md. Validated per spec section 10: root CI green, throwaway bootstrap (Task 15) green, capstone upgrade dry-run (Task 16) one-run clean."
```

- [ ] **Step 2: After merge (release):** tag per `<release-process>`: `git tag v2.0.0 && git push origin v2.0.0`. Only then does the pinned one-liner resolve.

---

## Self-Review (performed at write time)

- **Spec coverage:** Pillar 1 -> Tasks 2, 5, 6; Pillar 2 -> Tasks 3, 6; Pillar 3 -> Tasks 7, 8; Pillar 4 -> Tasks 2 (visual baseline), 3 (ship-record), 8 (e2e step), 9, 10; Pillar 5 -> Tasks 4, 11, 16; Pillar 6 -> Task 12; rollout/validation -> Tasks 13-17. Deviation from spec, deliberate: the visual-design guidance ships inside `<design-discipline>` (already UI-scoped by its own wording) instead of a new conditional fence -- render_smoke's fence regex only strips `AI-*` fences, and a new fence type would need three registry updates for zero behavioral gain.
- **Placeholder scan:** all new placeholder names enumerated in Task 8 and consumed in Task 9; COMMON additions cover every one (checked name-by-name).
- **Type/name consistency:** `docs/designs/<slice>.md`, `docs/probes/<slice>-<name>.md`, `Approved: <date>`, `FW-BLOCK`, `DESIGN_FLAW`, `TODO(interview-skipped)`, and the A/B question IDs are used identically across Tasks 2, 4, 5, 6, 7, 8, 11, 15, 16.
