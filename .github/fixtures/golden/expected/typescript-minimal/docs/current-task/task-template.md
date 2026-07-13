# Current Task

> Copy this template over `task.md` when starting a new task.
> The main-context driver (you, in Claude Code) and each subagent (spec-writer, implementer, reviewer) append their own section as they work. The upstream `tdd` skill (mattpocock/skills) provides the Red to Green to Refactor methodology when invoked.

## Brief

**Title:**

**Description:**

**Why this task:**

**Estimated effort:** S / M / L

## Acceptance criteria

The contract for this task: numbered (slice-scoped `AC1..n`), observable, each one
proven by a test named in the test plan below, and each citing the iteration
`REQ-AC` it advances (from `docs/requirements.md`). The task is not done until every
criterion maps to a covering test (gate-run tests pass; an e2e-only criterion is
present and run by CI -- the reviewer checks the mapping).

- [ ] **AC1** (advances REQ-AC?):
- [ ] **AC2** (advances REQ-AC?):
- [ ] **AC3** (advances REQ-AC?):

## Relevant docs and files

- `docs/requirements.md` (sections: TODO)
- `docs/gotchas.md` (relevant entries: TODO)
- Existing code: TODO

## Plan (by main-context driver, or inline for small tasks)

<!-- Run the planning pass in AGENTS.md <planning-discipline> before writing code --
     for EVERY non-trivial task, not just the first: brainstorm the options, then
     grill the chosen one (grill-me). For tasks under 1h, this can be a few lines;
     do not skip the security row. -->

- **Options considered (brainstorm -- name at least two, and why this one):**
- **Core journey (what the user sees):**
- **Concrete examples (inputs / outputs / file to pattern-match):**
- **Design memo (path + `Approved:` date -- REQUIRED before any code, see <investigation-discipline>):**
- **Riskiest assumption (de-risked by which probe/spike):**
- **Reality probes (docs/probes/ files this slice's fixtures are authored from):**
- **Non-goals (explicitly out of this slice):**
- **Unhappy paths + attacker story (error states, edge inputs; the attack as a story if security-triggered):**
- **Data shapes at each boundary:**
- **Security surface (which canonical-trigger clause from <delivery-evidence>, which SECURITY.md defense, and the threat-model disposition):**
- **Autonomy (attended, or the <loop-discipline> envelope if any part runs unattended):**
- **Mockup (any slice that makes a visible UI/UX choice gets a mockup, approved by the user before the design memo is approved -- path/link + approval):**
- **What might be missing (proactive pass -- error states, empty/edge inputs, auth, scale, observability):**

### Test plan (name every test before code -- see <test-discipline>)

Tag each test with the acceptance criterion it proves (`(AC1)`, `(AC2)`, ...). Every
AC above must appear on at least one line here; if one doesn't, it isn't testable as
written -- sharpen the criterion.

- [ ] Unit:
- [ ] Functional / API:
- [ ] End-to-end (headless browser if UI, else full request->state):
- [ ] Security / red-team (if the slice adds an attack surface):
- [ ] Live smoke check (required when the suite above is fake-only -- the one scripted real-system check):

**Coverage:** AC1 -> ; AC2 -> ; AC3 -> .

## Spec (by test-spec-writer)

<!-- Tests added, what they cover, where they live. The full pyramid from the test plan. -->

## Implementation notes (by implementer)

<!-- Decisions made, trade-offs, deviations from plan, files touched. -->

## Review (by code-reviewer)

<!-- Verdict (APPROVE / APPROVE_WITH_NITS / REQUEST_CHANGES), QA gate result, issues found. -->

## Outcome

<!-- Once task is complete: -->
<!-- - Ship record written at docs/ships/<slice>.md (REQUIRED before the backlog row moves -- see <delivery-evidence>): -->
<!-- - Commit hash: -->
<!-- - PR link: -->
<!-- - Gotchas added to docs/gotchas.md: -->
<!-- - Structure changes recorded in docs/structure.txt: -->
