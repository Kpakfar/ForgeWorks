# Product Vision: Briefly

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **An engineering manager who writes the same status update every Friday.**
who **writes the same status update every Friday**,
Briefly is a **evidence-linked status brief generator**
that **drafts the brief with receipts, so editing replaces writing**.
Unlike **hand-assembling updates from tickets, PRs, and chat**,
we **every claim carries a link to its evidence, and unsupported claims are flagged**.

## 5W answers

- **Who:** An engineering manager who writes the same status update every Friday.
- **What:** A web app that turns a team's weekly activity into a two-paragraph stakeholder brief.
- **Why:** Weekly stakeholder updates are assembled by hand from tickets, PRs, and chat; the writing is repetitive and the gathering is worse.
- **When:** 2026-08-23
- **Where:** Internal web app on the company PaaS.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Export import and per-claim evidence linking.
- LLM-drafted two-paragraph brief with inline editing.
- Faithfulness flagging for unsupported claims.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No live integrations in the first iteration; file export import only.
- No scheduling or sending; the manager copies the brief out.

## Business goals

Outcome + metric + target. Cap at three.

- time to approved brief -- under 5 minutes
- claims with a working evidence link -- 100%

## Success looks like

> A manager produces an approved, evidence-linked brief in under five minutes, down from thirty.

---

*Last updated: 2026-07-12*
