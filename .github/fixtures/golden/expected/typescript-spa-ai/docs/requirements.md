# Requirements: Briefly

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

A web app that turns a team's weekly activity into a two-paragraph stakeholder brief.

## Why

Weekly stakeholder updates are assembled by hand from tickets, PRs, and chat; the writing is repetitive and the gathering is worse.

## Who

**Primary user:** An engineering manager who writes the same status update every Friday.

Other potential users (deferred to later iterations):
- Product managers assembling roadmap updates (deferred).

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. The manager connects the team's issue tracker export.
2. The app drafts a two-paragraph brief with linked evidence for every claim.
3. The manager edits inline and copies the approved brief out.

**Success looks like:** A manager produces an approved, evidence-linked brief in under five minutes, down from thirty.

**Riskiest assumption** (test this first): An LLM can draft claims that are faithful to the underlying tickets often enough that editing beats writing from scratch.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** Importing a week's export yields a draft brief with every claim linked to at least one source item.
- [ ] **REQ-AC2:** Editing a paragraph and approving produces a copyable final brief.
- [ ] **REQ-AC3:** A claim with no supporting source is visually flagged, never silently kept.

## Stack

- **Language:** TypeScript Node 22 (LTS) / TypeScript 5.7+
- **Package manager:** npm
- **Quality-gate command:** npm run qa
- **Test runner:** vitest
- **Lint / format / type-check tools:** eslint / prettier / tsc
- **Frontend:** yes-spa
- **Backend framework:** Next.js
- **Database / persistence:** Postgres
- **Vector store:** none
- **LLM provider:** Anthropic
- **Embeddings model:** none
- **Dev container:** no
- **Deployment target:** Internal web app on the company PaaS.
- **Scale expectations (first iteration):** Two pilot teams, about 20 briefs per week.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- Issue-tracker CSV/JSON export (file import).
- Anthropic API (drafting and faithfulness evals).
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## AI features in scope

agents, evals

Describe the approach per feature as it is designed -- each AI feature's design
lands in its slice's design memo (`docs/designs/`), and this section links them.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): yes
- **Holds private data** (user records, secrets, anything non-public): yes
- **Acts on the outside world** (sends, writes externally, side-effecting tools): no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No live integrations in the first iteration; file export import only.
- No scheduling or sending; the manager copies the brief out.

## Constraints

- Time: Six weeks to an internal pilot with two teams.
- Cost: LLM budget USD 50/month for the pilot; one draft must cost under USD 0.10.
- Data: Ticket exports may contain internal names; data stays in the company tenancy and drafts are deleted after 30 days.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
