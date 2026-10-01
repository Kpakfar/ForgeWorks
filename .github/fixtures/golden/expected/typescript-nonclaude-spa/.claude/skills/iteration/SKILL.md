---
name: iteration
description: >-
  The per-feature workflow. Use when starting any feature, change, or fix:
  "build F003", "next feature", "add X", "fix Y". Chores build straight
  through; features run GRILL -> RED -> GREEN -> REVIEW -> MERGE with caps.
---

# iteration -- one bounded loop per feature

State lives in the feature's `docs/features.json` entry. Update it with
`python3 scripts/feature.py <id> key=value`; every phase change sets `phase`
and `next` (the single next action) in one command. No state change without
evidence: test output, the command run, or a screenshot path.

## 0. Route

**Chore** (the diff fits in one sentence, no behavior change): make the
change, run `npm run qa`, commit. Nothing else.

Anything else is a **feature**. No entry yet? Add one: next free id,
`status: todo`, `tier: feature`, `surface:` the screen it touches or
`"none"`, `serves:` a `docs/PRD.md` section (cannot name one? question the
feature). Unsure which tier? Feature.

## 1. GRILL -- decide, then the one owner gate

`status=in-progress phase=grill`. Write `docs/plans/<id>.md` with these
sections and nothing else:

- **Decisions.** What the owner asked, in their words. Every decision made,
  including "owner said no to X". The riskiest bit and how it is de-risked.
- **Approach.** Data shapes at the boundaries, files to touch, out of scope.
- **Threat model** (only when the `security-review` trigger matches): the new
  attack surface, who sends what through it, the validation point per input
  (allowlist at the boundary, fail closed), what an attacker tries first,
  and the security tests by name. Rule of Two: untrusted input + private
  data + outward action means drop one leg or gate the action behind the
  owner.

Acceptance criteria live only in the entry's `acceptance` array, one EARS
line each (`WHEN <condition> THE SYSTEM SHALL <behavior>`). Each becomes a
named test in RED. A surface feature needs a mockup before RED: build 3-4
genuinely different HTML options (layouts, not recolors; real content;
values from the tokens file), the owner picks, commit the winner to
`docs/design/mockups/<id>-<name>.html` and set `mockup=` on the entry.

Then attack the plan: strongest objection, failure modes, a simpler
alternative. Present it in the `<communication>` GRILL shape. The owner
approves once, here. Write every decision from the conversation back into
the plan; a decision that lives only in chat does not exist. The plan must
let a fresh session execute the feature alone and fit the plan cap the
`docs-budget` job enforces. Decisions, not narrative.

## 2. RED

Branch `feat/<id>-<slug>`; `phase=red`. One failing test per acceptance
line, plus the threat model's tests; add each with `tests+=`. Confirm each
fails for the right reason. Evidence: the failing run.

## 3. GREEN

`phase=green`. Implement in this context: the least code that passes, then
refactor (dead code out, one concept per file, built against the approved
mockup with values from the tokens file). Extract shared code at the second
real caller, not before. Exit: `npm run qa` and
`python3 scripts/dup_check.py` green (`--baseline` accepts today's findings
and still fails new ones; prefer it over a permanent `.dup-ignore` path).
**Stall cap:** two failed cycles on the same failure. Checkpoint, stop, ask.

A `surface: "none"` feature whose tests are complete may go to a cheaper
model on a job card: `reference/dispatch.md`.

## 4. REVIEW

`phase=review`. Dispatch `@reviewer` with a minimal brief: the plan path,
the branch or diff, the doc sections to grep, the mockup path if visual.
Fix blocking findings directly. **Caps:** two fix passes; one re-review,
which continues the same reviewer conversation; one design rework. A cap
hit stops and asks in the `<communication>` cap-hit shape.

## 5. MERGE

1. `npm run qa`, `npm run e2e`, `python3 scripts/features_check.py` green.
2. Merge to main (from a worktree: `bash scripts/land.sh`); delete the
   branch; `bash scripts/factory_doctor.sh` reports no worktree left behind.
3. `status=done` (cited tests exist and pass, a hard rule). Move what still
   changes a future decision: a lesson to `docs/gotchas.md`, a security
   delta to `docs/SECURITY.md`, owed work to `notes` or a new todo entry.
   Carry a status verbatim or delete it; never reword an obligation into a
   claim.
4. `python3 scripts/prune.py`: deletes the plan, losing mockups, and
   uncited probes, then regenerates `docs/BACKLOG.md`.
5. Merge report: three lines.

## Deviations and surprises

Must deviate from the plan or mockup? Take the conservative option, append
one line with `notes+=`, keep going. Reality surprised you? One four-line
`docs/gotchas.md` entry. Off-scope ideas become todo entries, never scope
creep.

## CHECKPOINT -- before any clear, and whenever a decision lands

1. Decisions made in chat since the last checkpoint go into the plan (or
   `acceptance`).
2. Unfixed reviewer findings go into the plan under `## Review findings
   (open)`, one line each.
3. Work in progress becomes a `wip:` commit. Uncommitted work is luck, not
   state.
4. `python3 scripts/feature.py <id> next="..."`, then
   `python3 scripts/resume.py`. If it refuses, fix the contradiction now.

After this, `/clear` then `go` costs nothing. Offer a clear as one line
inside a report you were already writing, and only when the next action
needs nothing from this conversation. Never as a question, never
mid-orchestration.
