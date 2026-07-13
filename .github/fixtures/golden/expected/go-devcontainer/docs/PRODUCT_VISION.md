# Product Vision: Feedgate

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **A data engineer who babysits broken partner feeds every Monday.**
who **babysits broken partner feeds every Monday**,
Feedgate is a **feed validation gateway**
that **stops broken feeds before they corrupt the pipeline**.
Unlike **letting feeds into the pipeline and cleaning up after incidents**,
we **validates and quarantines at the front door instead of repairing downstream**.

## 5W answers

- **Who:** A data engineer who babysits broken partner feeds every Monday.
- **What:** An internal HTTP service that validates and normalizes partner RSS feeds before ingestion.
- **Why:** Partner feeds break silently (bad encodings, missing fields, wrong dates) and corrupt the downstream pipeline; validation happens too late, after ingestion.
- **When:** 2026-07-26
- **Where:** Internal service in the company Kubernetes cluster.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Feed registration, fetching, and strict-schema validation.
- Encoding and date normalization.
- Quarantine with actionable error reports and a status endpoint.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No feed content transformation beyond encoding/date normalization.
- No partner-facing UI; engineers query the status endpoint.

## Business goals

Outcome + metric + target. Cap at three.

- pipeline incidents caused by bad feeds -- zero after rollout
- validation latency per feed -- p95 under 500ms

## Success looks like

> A malformed feed is quarantined with an actionable error report instead of reaching the pipeline, and a clean feed passes through unchanged.

---

*Last updated: 2026-07-12*
