# ForgeWorks v2.0.0 -- design-first, token-lean, seamlessly upgradable

- **Date:** 2026-07-09
- **Status:** Approved by owner (design review 2026-07-09); spec pending owner read-through
- **Drives:** the v2.0.0 release (breaking; carried to old projects by `upgrade-project`)

## 1. Why v2 exists

v1.x was used on real projects and failed its owner in five ways. Each failure is
evidence-backed by an audit of this repo (v1.1.4) and a post-mortem of a generated
project (`turingcollege/capstone`, stamped v1.1.4):

1. **Design phase too short; system rushes to code.** Only UI has a pre-code gate
   (mockup-first). Technical/architectural decisions have no required artifact --
   "spike" appears once in the whole core, as an optional exception. Planning's
   "done" condition is a list of tests, which pulls straight into code.
   Capstone evidence: a 2.9 KB optimistic research note green-lit building the
   entire product on GBrain; 21 slices later it was ripped out and replaced
   (slice 022). The owner's own reset doc names the mechanism: *"code had a gate
   and prose didn't."* Same signature repeated at smaller scale: SSE chat shipped
   green against 323 tests while dead against the real backend (spike observed
   endpoint A, code called endpoint B); a schema approved twice against fakes was
   wrong against the real collaborator; a trigger built on a field (`gaps`) that
   six real calls proved always-non-empty.
2. **Token-intensive; rabbit holes.** No rule anywhere bounds context, re-reads,
   review rounds, or fix-rounds. Every subagent re-reads the same 5-6 docs;
   Context7 fires on every library touch; `@security-reviewer` defaults to opus
   after nearly every slice; the QA gate runs twice per review. Capstone evidence:
   28 MB of AI transcripts in `.local/research/`; one slice accumulated 38
   fix-round references; a single fix transcript of 8.4 MB. After the owner
   manually imposed discipline (plan-v4: one review round, briefs on disk,
   right-sized models) waste dropped ~20-40x per slice.
3. **Interview under-elicits the product.** 9 of 15 questions are stack/tooling;
   3 are product. Never asked: acceptance criteria, non-goals (the placeholder
   exists, no question feeds it), constraints/budget, deployment target, scale,
   success metrics, external integrations, other user segments. All ship as TODO
   and surface later as surprises.
4. **Generated output disappoints.** Fresh docs are largely TODO/empty-slot;
   interview answers that exist (Q1 user, Q2 problem) are not wired into
   `PRODUCT_VISION.md`'s positioning slots; the mockup trigger contradicts itself
   across three files; no prototype/mockup skill is installed; zero visual-design
   guidance.
5. **Upgrade is not seamless.** No mechanism to fill interview-sourced
   placeholders in files added by newer versions; mem0 unrecoverable;
   `quality-gate.sh` falls between the copy rules; AGENTS.md grafting is agent
   judgment over a ~200-line constitution with a one-entry supersession registry;
   nearly every step punts to "show the user / report as manual."

## 2. Owner decisions (fixed inputs to this design)

- **Hard design gate**, user-approved: the agent may not write feature code for a
  non-trivial slice until the owner has approved that slice's design memo (and
  mockup, for UI). No reviewer-agent shortcut; the owner approves everything.
- **v2.0.0 is a breaking release.** `upgrade-project` v2 must carry v1.x projects
  across the break in one run.
- **caveman + ponytail: distill, don't depend** (recommended and accepted).
  Their rules are baked into the generated core as always-on text; no external
  plugin dependency. `caveman` the skill stays in the Phase 1 install list as a
  convenience, but the core rules do not require it. Ponytail
  (github.com/DietrichGebert/ponytail) is credited where its ladder is used.

## 3. Non-goals

- No new language profiles (Rust stays experimental).
- No deterministic scaffold engine or golden-fixture CI (still ROADMAP).
- No change to the bootstrap split (bootstrap stays dumb and stack-blind).
- Not a rewrite of TDD discipline itself -- red/green/refactor stays; v2 changes
  what must happen *before* Red.

## 4. Pillar 1 -- Reality-first design gate

New always-on block in `templates/core/AGENTS.md`: **`<investigation-discipline>`**.

1. **Reality probe (the GBrain rule).** Before building on any external
   collaborator (library, API, service, protocol, data source) or pinning any
   interface, the agent must make at least one *real* observation of it -- a real
   call, a real dispatch, a real run -- and record the observed request/response
   on disk under `docs/probes/<slice>-<name>.md`. Test fixtures and fakes may
   only be authored from a recorded probe, never from documentation, README
   claims, a sibling endpoint, or memory. A fixture built from a description of
   endpoint A does not verify endpoint B.
2. **Spike as a gate, not a footnote.** If a slice contains an unknown the team
   cannot answer from the codebase or a probe, a bounded spike (in
   `experiments/`, no TDD) runs first, and its verdict -- including red flags --
   goes into the design memo. A spike that surfaces red flags cannot be
   summarized as "assumptions HOLD"; each red flag needs a stated mitigation or
   an explicit owner acceptance.
3. **Design memo -- the hard gate.** Every non-trivial slice starts with a memo
   of one page or less at `docs/designs/<slice>.md`: problem, 2-3 candidate
   approaches with trade-offs, chosen approach and why, riskiest assumption and
   the probe/spike result that de-risks it, and the test plan (unit /
   functional / e2e, plus the live smoke check -- see 4.5). **The agent is
   forbidden to write feature code (including Red-phase tests) until the owner
   has approved the memo.** "Non-trivial" = anything beyond the existing
   `<exceptional-cases>` trivial list (typo/comment/doc-only edits, pure renames,
   config value changes).
4. **Mockup gate, made consistent.** One canonical trigger, stated identically in
   `<design-discipline>`, `<planning-discipline>`, and `task-template.md`:
   *"any slice that makes a visible UI/UX choice gets a mockup, approved by the
   owner before the design memo is approved."* The "complicated and" qualifier is
   removed.
5. **Live smoke check pairs with every fake-only suite.** If a slice's tests run
   entirely against fakes, its acceptance criteria must include one scripted
   check against the real system (real server boot, real endpoint hit, real tool
   dispatch), and the ship-record must link its output. Green fakes alone do not
   ship. Security-control proofs must exercise the real enforcement path with
   the live path's flags, not an introspection endpoint.

Supporting changes:

- `<planning-discipline>` reworded so "done" = *approved design memo* (which
  contains the test list), not the test list itself.
- `docs/designs/` and `docs/probes/` added to `templates/core/` with short
  READMEs; `docs/structure.txt` updated.
- `.claude/agents/implementer.md` gains a hard precondition: refuse the task and
  say why if the current slice has no approved design memo.

## 5. Pillar 2 -- Token discipline (caveman + ponytail, distilled)

New always-on block in `templates/core/AGENTS.md`: **`<token-discipline>`**.

1. **Terse by default (caveman-derived, inlined).** Agent working output --
   status updates, inter-agent briefs, review notes -- uses compressed prose:
   drop filler/pleasantries/hedging, fragments OK, technical terms exact, code
   and errors quoted exactly. Full prose is reserved for: design memos, security
   warnings, irreversible-action confirmations, and user-facing docs. The rules
   are inlined so they hold even where the `caveman` skill is absent.
2. **The ponytail ladder (credited).** Before writing any new code, walk:
   does this need to exist -> already in this codebase -> stdlib -> platform
   feature -> installed dependency -> one line -> only then the minimum that
   works. Lazy about solutions, meticulous about analysis: the ladder never
   replaces the probe/spike, it follows it.
3. **Fix-round circuit breaker.** Max two fix-rounds per review finding. A third
   failure means STOP: the design was wrong, return to the design memo and
   re-open it with the owner. (Kills 38-round sagas.)
4. **One review round by default.** `@code-reviewer` runs once per slice;
   re-review only for findings the circuit breaker hasn't tripped on.
5. **Scoped reads.** The unconditional "always read structure.txt +
   requirements.md + AGENTS.md" mandates become scoped: the orchestrating
   session reads them once; each subagent brief states exactly which docs that
   task needs, and the subagent reads only those. Briefs live on disk
   (`docs/current-task/`), not re-narrated per hop.
6. **Right-sized models, stated explicitly.** Every subagent declares its model.
   `@security-reviewer` drops from opus-by-default to the session's default
   model, with a documented escalation ("use the strongest available model when
   the slice touches auth, payments, or data deletion"). Mechanical work
   (explanation memos, doc formatting) states the cheapest model.
7. **Context7 scoped.** Look up a library's docs on *first* use in the project or
   when using a version-sensitive API -- not on every touch. Probe results and
   prior lookups are the cache.
8. **Gate runs once per actor.** The reviewer trusts the Stop-hook's
   `{{QA_COMMAND}}` run instead of running it a second time itself; CI remains
   the final independent run.

## 6. Pillar 3 -- Interview redesign (init-project)

The interview becomes two parts. **Part A: product discovery** (expanded, first);
**Part B: stack and options** (tightened, second). Rule zero: **nothing the
interview can elicit ships as TODO.**

Part A asks, in order: primary user; core problem; core journey (the one flow
that must work); **acceptance criteria for slice 1** (verifiable, they become the
contract); **non-goals** (explicitly asked, feeds the existing placeholder);
success metric; riskiest assumption; **constraints** (time, cost/LLM budget,
data/licensing); **deployment target** (where it runs); **scale/performance
expectations**; **external systems and integrations** it must talk to; other user
segments. Grill-style follow-ups are mandated when an answer is vague ("How would
you verify that?" / "What breaks first?").

Part B keeps language, AI features, security profile, Codex reviewer, opt-in docs
-- with concrete per-language menus for the framework question (no more
"Example for Python: ..." improvisation).

Emission changes:

- Every Part A answer is wired into the docs: `PRODUCT_VISION.md` positioning
  slots and 5W filled from interview answers; constraints/deployment/scale/
  integrations/metrics/other-users land in `requirements.md`; ACs land as
  REQ-AC1..n. Phase 4 rule 7 ("must not be TODO") is extended to cover all of
  them.
- `PRODUCT_VISION.md` and `requirements.md` are de-duplicated: vision owns
  who/why/positioning; requirements owns what/criteria/constraints; each links
  to the other.
- Phase 3 (confirm plan) shows the owner the *filled docs preview*, not just a
  settings summary -- surprises surface before generation, not after.

## 7. Pillar 4 -- Generated-output quality

- **Visual-design guidance block** (compact, ~30 lines) shipped for UI projects:
  typography scale, spacing rhythm, one accent color, layout-before-decoration,
  and "match the style reference" -- enough to keep improvised mockups from
  looking templated. A prototype/mockup skill is installed in Phase 1 if one is
  available in the configured skill packs; the guidance block works without it.
- **Profile hardening from the capstone** (Python profile): pytest
  `--import-mode=importlib`; flake8-bugbear
  `extend-immutable-calls = [fastapi.Depends, File, Body, Query]` documented for
  FastAPI projects; the `TYPE_CHECKING`-guarded-import split rule; the
  `Depends()`-vs-bare-call DI rule -- recorded in the Python
  `language-standards.md` so the next project doesn't rediscover them.
- **Ship-records stamp a rework count.** The per-slice ship-record commit
  includes "review rounds: N, fix rounds: M" so squash-clean history cannot hide
  churn from a later post-mortem.
- **CI e2e step made deterministic:** Phase 4 substitutes the browser-install
  step via a placeholder/conditional instead of asking the agent to remember to
  uncomment lines.

## 8. Pillar 5 -- Seamless upgrade (upgrade-project v2)

Target: **one run, one batched approval, zero half-written placeholders.**
Acceptance test: upgrading `turingcollege/capstone` (v1.1.4) to v2.0.0 in a
single run.

1. **Mini-interview for discovery placeholders.** When a newer-template file
   carries interview-sourced placeholders the repo scan cannot recover
   (e.g. `{{SUCCESS_MEASURE}}`, `{{NON_GOALS}}`, the new Part A fields), the
   upgrade asks the owner exactly those questions -- batched, once -- instead of
   punting to "add manually."
2. **Deterministic block grafting.** Every rule block in
   `templates/core/AGENTS.md` gets a stable marker comment
   (`<!-- FW-BLOCK: token-discipline v2.0.0 -->` ... `<!-- /FW-BLOCK -->`).
   Grafting becomes a mechanical diff on markers: absent -> insert; present but
   older version -> show side-by-side once; present and current -> skip.
   The supersession registry becomes a real table (every rename/merge since
   v1.0.0, starting with `<starting-a-slice>` -> `<planning-discipline>` and all
   v2 renames), and idempotency is checked by marker, not judgment.
3. **Capability recovery extended:** detect mem0 (`docs/memory.md` /
   `<memory>` block), detect `quality-gate.sh` and regenerate it from the
   recovered `{{QA_COMMAND}}` in `language-standards.md`, detect prior
   probes/designs dirs.
4. **Batched approval.** The upgrade computes the full change set, presents ONE
   report (copy verbatim / graft / substitute / needs-your-answer / superseded),
   collects answers and a single yes, then applies everything and re-runs the QA
   gate. Per-change prompting is removed.
5. **Version refs stop drifting by hand:** the pinned reconcile ref is read from
   `VERSION` at release time by a release checklist item, and the upgrade report
   prints from->to using `.claude/.template-version`.

## 9. Pillar 6 -- Repo hygiene (this repo)

- Remove the duplicated "First, confirm..." line at `init-project/SKILL.md`
  Phase 5 (~L369-371).
- Verify `handoff` exists in the mattpocock skill pack; if not, drop or replace
  the reference in `init-project/SKILL.md` Phase 1 and `bootstrap/AGENTS.md`.
- Pin `@upstash/context7-mcp` to a version in `templates/core/.mcp.json`
  (removes the internal contradiction with `<security-discipline>`).
- Fix the stale `e.g. 1.0.0` illustration in this repo's `AGENTS.md`.
- Register any new fence markers and the FW-BLOCK convention in all three
  registries (init SKILL Phase 4 rule 5, upgrade SKILL Phase 3-A, repo
  AGENTS.md `<editing-the-template>`).

## 10. Rollout and validation

1. All work on a branch; PR per `<conventions>` (touches Phase 4, core AGENTS.md,
   both SKILLs).
2. `VERSION` -> 2.0.0; pinned refs updated per `<release-process>`.
3. Validation, in order:
   a. Root CI render-smoke stays green (no leftover placeholders, profiles pass).
   b. Bootstrap a throwaway project with `BRANCH=<v2 branch>`; walk the new
      interview; confirm: zero elicitable TODOs in generated docs, design-gate
      blocks present, marker fences present, QA green on first run.
   c. Dry-run `upgrade-project` v2 against a copy of `turingcollege/capstone`;
      confirm one-run completion, the mini-interview fires for exactly the
      missing discovery fields, no `{{...}}` left behind, QA gate still green.
   d. Tag v2.0.0 only after (b) and (c) pass.

## 11. Success criteria for the release itself

- A generated project's agent cannot reach feature code without an
  owner-approved design memo (and mockup where UI) -- verified by reading the
  generated AGENTS.md + implementer precondition in the throwaway.
- A generated project contains the reality-probe rule, the ladder, the circuit
  breaker, and terse-by-default -- all always-on, no external dependency.
- The new interview produces docs with zero elicitable TODOs.
- The capstone upgrades in one run with one batched approval.
