---
name: iteration
description: >-
  The per-feature workflow. Use when starting any feature, change, or fix:
  "build F003", "next feature", "add X", "fix Y". Chores build straight
  through; features run GRILL -> RED -> GREEN -> REVIEW -> REPLAN -> MERGE
  with caps.
---

# iteration -- one bounded loop per feature

State lives in the feature's `docs/features.json` entry. Update it with
`python3 scripts/feature.py <id> key=value`; every phase change sets `phase`
and `next` (the single next action) in one command. That script owns the
edges: it refuses a start before a dependency is done, a skipped phase, a
GREEN with no cited test, a close that did not pass REVIEW, and a REVIEW
past its cap. A refusal means stop and ask.
With the owner's yes, repeat the command with `override="<their reason>"`.

## 0. Route

**Chore** (the diff fits in one sentence, no behavior change): make the
change, run `{{QA_COMMAND}}`, commit. Nothing else.

**Fix** (the code breaks a line in an entry's `acceptance`; the line itself
stays): write the regression test and watch it fail, make it pass, run
`{{QA_COMMAND}}`, commit with `fix:`, and record it on that entry with
`tests+=` and one `notes+=` line. No plan and no new owner gate: the owner approved that line at
its GRILL. A security-trigger match still gets the security lens before the
merge. A fix that needs a changed acceptance line is a feature.

Anything else is a **feature**. No entry yet? Add one: next free id,
`status: todo`, `tier: feature`, `surface:` the screen it touches or
`"none"`, `serves:` a `docs/PRD.md` section (cannot name one? question the
feature). Unsure which tier? Feature.

`depends_on` lists the entries whose output this one consumes. Name what
crosses the edge (a table, an endpoint, a module); if you cannot, there is no
edge. Entries with no edge between them can be built in parallel worktrees.

## 1. GRILL -- decide, then the one owner gate

Branch `feat/<id>-<slug>`; `status=in-progress phase=grill`. Write
`docs/plans/<id>.md` with these sections and nothing else:

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
named test in RED. A surface feature needs a mockup before RED. A new
surface gets 3-4 genuinely different HTML options (layouts, not recolors;
real content; values from the tokens file); a change to a surface that
already has an approved mockup gets one, shown beside the old. The owner
picks, commit the winner to
`docs/design/mockups/<id>-<name>.html` and set `mockup=` on the entry.

Then attack the plan: strongest objection, failure modes, a simpler
alternative. Present it in the `<communication>` GRILL shape. The owner
approves once, here; the approval covers merging this scope locally, and a
changed acceptance line needs a new one. Write every decision from the conversation back into
the plan; a decision that lives only in chat does not exist. The plan must
let a fresh session execute the feature alone and fit the plan cap the
`docs-budget` job enforces. Decisions, not narrative.

## 2. RED

`phase=red`. One failing test per acceptance
line, plus the threat model's tests; add each with `tests+=`. Confirm each
fails for the right reason. Evidence: the failing run.

## 3. GREEN

`phase=green`. Implement in this context: the least code that passes, then
refactor (dead code out, one concept per file, built against the approved
mockup with values from the tokens file). Extract shared code at the second
real caller, not before. Exit: `{{QA_COMMAND}}` and
`python3 scripts/dup_check.py` green (`--baseline` accepts today's findings
and still fails new ones; prefer it over a permanent `.dup-ignore` path).
**Stall cap:** two failed cycles on the same failure. Checkpoint, stop, ask.

A `surface: "none"` feature whose tests are complete may go to a cheaper
model on a job card: `reference/dispatch.md`.

## 4. REVIEW

`phase=review`. Dispatch `@reviewer` with a minimal brief: the plan path,
the branch or diff, the doc sections to grep, the mockup path if visual.
Fix blocking findings directly, and only what each finding names. A
finding that misreads the plan or names no real defect may be declined:
`notes+="declined: <finding> -- <reason>"`. A decline does not close
REVIEW. The re-review rules on it. Each new pass sets `phase=green`, then `phase=review` again. **Caps:**
`feature.py` counts the reviews and refuses one past its cap; the re-review
continues the same reviewer conversation; one design rework. A cap
hit stops and asks in the `<communication>` cap-hit shape.

## 5. REPLAN -- close the feature on its branch, then re-aim

Everything here is committed on the feature branch, so it lands with the
feature. Nothing is edited on main after the merge.

1. `{{QA_COMMAND}}`, `{{E2E_COMMAND}}`, `python3 scripts/features_check.py` green.
2. Move what still changes a future decision out of the plan: a choice that
   binds later work ("owner said no to X") to the entry with `decisions+=`,
   a lesson to `docs/gotchas.md`, a security delta to `docs/SECURITY.md`,
   owed work to `notes` or a new todo entry. Carry a status verbatim or
   delete it; never reword an obligation into a claim.
3. `status=done` (cited tests exist and pass, a hard rule).
4. The inner loop fixed one feature. Now fix the plan that produces
   features. Three questions; "no change" is a valid answer to each.
   - **Does `docs/PRD.md` still describe the product?** If the feature
     proved a line wrong, propose the edit. The owner confirms every PRD
     change before the merge.
   - **Is the next entry still the right one?** `python3 scripts/resume.py`
     names it. Reorder, drop (`status=dropped` with the reason), split, or
     add entries, and fix any `depends_on` this feature made false.
   - **Did this feature teach something the next one must obey?** Write it
     where the next GRILL reads it: a `decisions` line, a gotcha, or the
     PRD. At most one, and only with evidence.
5. `python3 scripts/prune.py`: it deletes the plan, losing mockups, and
   uncited probes, and regenerates `docs/BACKLOG.md` from the entries as
   REPLAN left them. `python3 scripts/features_check.py` green. Commit.

## 6. MERGE

Merge to main (from a worktree: `bash scripts/land.sh`); delete the branch;
`bash scripts/factory_doctor.sh` reports no worktree left behind. Then the
merge report, three lines; "next up" is the entry REPLAN chose.

## Owner gates -- what the GRILL approval does not cover

The GRILL approval covers building this scope and merging it locally. It
never covers an action that is hard to undo. Each of these stops and asks,
every time, with one line saying what will happen and what is lost if it is
wrong:

- Deleting data, or files the plan did not name. (`scripts/prune.py`
  deleting a closed feature's plan is not this: git keeps it.)
- A migration that drops or rewrites stored data.
- Pushing, opening or merging a pull request, tagging a release, deploying.
- Publishing or sending anything outward: a post, an email, a message, a
  package.
- Moving money, or changing access, secrets, or billing.

Name any such action in the plan's Decisions at GRILL so the owner sees it
early. The yes is still asked at the moment of the action; an earlier
"do all of it" does not count. Unsure whether an action belongs here? It does.

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
