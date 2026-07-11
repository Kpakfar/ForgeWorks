# Loop engineering vs the ForgeWorks philosophy — investigation + options

Source: 2026-07-11 review requested by the maintainer, seeded by two articles
("Loop Engineering: The Karpathy Method" by @0xCodila; "Getting started with loops"
by @delba_oliveira / Claude Code team), extended with verified primary sources, and
adversarially converged with Codex 5.6 Sol (read-only in this repo). Status: analysis
+ options, nothing implemented.

## The doctrine (verified)

A loop = **goal + verifier the worker cannot game + persistent state + stop
condition** (goal met OR hard cap). Five building blocks: automation heartbeat,
skills, maker/checker split, connectors, verifier. A loop pays only when the task
repeats, verification is automated, the budget absorbs waste, and the agent has real
tools. Loop-contract fields to fix before starting: goal, scope, verifier, state,
stop, escalation, budget — plus (Codex additions) side-effect authority,
isolation/rollback, verifier completeness, flake handling, concurrent-loop
ownership, auditability.

- Karpathy autoresearch (github.com/karpathy/autoresearch, verified): agent edits
  ONLY `train.py`; `prepare.py` (evaluator, val_bpb metric) is off-limits;
  keep-or-revert per experiment. NOTE (Codex, correct): the protection is POLICY,
  not mechanism — the pattern works because the metric is scalar and the edit
  surface tiny. Product slices have neither.
- Bilevel Autoresearch (arxiv.org/abs/2603.23420, verified): outer loop reads the
  inner loop's traces and rewrites its search strategy; 5x on val_bpb
  (-0.045 vs -0.009), same LLM both levels — architecture, not intelligence.
- Claude Code loop taxonomy (code.claude.com/docs/en/goal, verified): turn-based /
  goal-based (`/goal`) / time-based (`/loop`, `/schedule`) / proactive. CRITICAL
  (Codex, correct): the `/goal` evaluator is a continuation driver, NOT a verifier —
  it judges only what the worker surfaced in the transcript, runs no commands.
  Deterministic hooks/CI must stay authoritative.
- Counterevidence (cerebras.ai "how to stop your autoresearch loop from cheating",
  fetched 2026-07-11): overnight unattended loops drifted off-objective within
  hours (agent silently swapped the research question; gamed the metric with no
  real progress); fixes were strict validation gates, isolated per-experiment
  environments, one-experiment-per-call, and MORE human check-ins.
- Honest costs both articles concede: comprehension debt (code nobody read,
  compound interest) and cognitive surrender (loop as a way to avoid thinking).

## Critique of the ForgeWorks philosophy

**Already loop-correct — keep, and it's ahead of the hype:** the verify-only QA
gate + reviewer Stop hook + CI is a real verifier stack; task/backlog/gotchas (and
planned ships/) are loop state; maker/checker subagent split; the 2-fix-round
circuit breaker is a no-progress stop; the memo/explanations/plain-English layer is
the anti-comprehension-debt machinery the loop articles only gesture at. The
Cerebras drift evidence validates human gates. The design memo is the human
supplying the objective function that product work, unlike GPT pretraining, does
not have. Philosophy to state explicitly: **the human is a gate, not the engine** —
approvals batch at slice boundaries; everything between boundaries is loopable.

**Genuine lags (field-confirmed in the capstone):**

- L1 — No heartbeat. Recurring security/tech-debt reviews are "rituals the
  orchestrator triggers"; post-v2.0.0 they fired zero times. Codex amendment
  (accepted): cadence should be EVENT-triggered first (slice classification, every
  N ships), with `/schedule` as a wall-clock backstop only — `/loop` is
  session-scoped and dies with the machine.
- L2 — End-states not packaged as goals. AC-to-test mapping exists in the task
  template (so "no goal definition" is overstated — Codex, accepted); the gap is
  emitting it as an executable `/goal` condition with turn/budget caps.
- L3 — Verification surface not change-controlled. During Green the same principal
  that writes code can edit the Red suite; only prose + review resist. A freeze
  hash is too blunt (legit test refactors) and too weak (same agent updates the
  hash) — Codex, accepted. Right shape: CI diffs the verification surface (tests,
  fixtures, snapshots, QA config, workflows) between Red and Green; changes require
  a recorded spec amendment + independent sign-off.
- L4 — Unattended mode undefined, so users improvise it. The capstone /goal
  finishing run + no-pause Stop hook WAS a user-built loop, and the harness's
  gates degraded silently inside it (grilling collapsed, security reviewer
  skipped). Binary attended/unattended mode is over-engineering (Codex, accepted):
  use a per-slice **autonomy envelope** instead; human gates PARK the slice and
  report, never silently convert.
- L5 — No budget/stop discipline beyond fix rounds: no default turn caps, no
  no-progress detection.
- L6 — Self-improvement (backport ritual) is a manual outer loop, per-project and
  human-run; nothing mines ship records/gotchas continuously.

## Converged options (both models agree; order = build order)

1. **Land v2.1.0 auditable delivery FIRST** (see
   `2026-07-11-v2.1.0-auditable-delivery.md`). Unanimous single highest-leverage
   change: the agent-neutral `slice-audit` ship gate turns skipped reviewers,
   missing evidence, and future loop-contract violations into visible failures
   even when orchestration degrades. Loops sit ON this substrate, never replace it.
2. **Autonomy envelope + rendered /goal** (S–M; new `loop-discipline` FW-BLOCK;
   touches `planning-discipline`, `token-discipline`, `exceptional-cases`,
   `task-specific-documents`). Design memo gains an envelope: allowed
   scope/side-effects, verifier paths, branch/worktree isolation, max
   turns/time/spend, no-progress rule, escalation, human-gate disposition
   (park-and-report). The harness renders a suggested `/goal` condition (AC map +
   "qa green" + cap) so unattended Green/fix phases run inside a contract instead
   of an improvised lean directive.
3. **Verifier-change control** (M; `test-discipline`, `quality-gate`,
   `investigation-discipline`, `delivery-evidence`): Red→Green diff of the
   verification surface; amendments need renewed approval + independent sign-off.
4. **Event-first cadence automation** (M; `recurring-reviews`, `agent-roster`,
   `quality-gate`, `delivery-evidence`): security review required by slice
   classification (already in v2.1.0 item 4); tech-debt every N shipped slices or
   pre-release, enforced via the ship-record audit; `/schedule` offered as backstop.
   No new bootstrap interview question.
5. **Bilevel-lite outer loop** (M; `self-improvement`, `recurring-reviews`):
   a read-only scheduled routine mines `docs/ships/` + `gotchas.md` and produces a
   candidate-lessons report for the human backport ritual. No auto-PRs until
   several runs prove signal quality.

## Disputes resolved during the dialogue

- Codex challenged the Cerebras drift story as mischaracterized, citing a
  different URL from memory (its sandbox has no network). Claude's version came
  from fetching the actual article the same day; the drift story, isolation fixes,
  and check-in advice are in the fetched text. Claude's characterization stands.
- Codex doubted the bilevel 5x number; the arXiv abstract (fetched) confirms it.
- Codex's corrections accepted: /goal-evaluator weakness, policy-vs-mechanism in
  autoresearch, L2 overstated, freeze-hash flaws, binary-mode over-engineering,
  event-before-calendar cadence, and six missing loop-contract fields.
