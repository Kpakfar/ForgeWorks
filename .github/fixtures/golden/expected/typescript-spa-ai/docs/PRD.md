# Briefly -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A web app that turns a team's weekly activity into a two-paragraph stakeholder brief.

Primary user: An engineering manager who writes the same status update every Friday. Problem: Weekly stakeholder updates are assembled by hand from tickets, PRs, and chat; the writing is repetitive and the gathering is worse.
Today's alternative: hand-assembling updates from tickets, PRs, and chat. Why this wins: every claim carries a link to its evidence, and unsupported claims are flagged

## The journey (end to end)

1. The manager connects the team's issue tracker export.
2. The app drafts a two-paragraph brief with linked evidence for every claim.
3. The manager edits inline and copies the approved brief out.

## Surfaces

- Brief editor
- Issue tracker connect

## v1 includes

- Export import and per-claim evidence linking.
- LLM-drafted two-paragraph brief with inline editing.
- Faithfulness flagging for unsupported claims.

## v1 excludes

- No live integrations in the first iteration; file export import only.
- No scheduling or sending; the manager copies the brief out.

## Success looks like

- time to approved brief -- under 5 minutes
- claims with a working evidence link -- 100%
