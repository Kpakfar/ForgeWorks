# Requirements: Feedgate

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

An internal HTTP service that validates and normalizes partner RSS feeds before ingestion.

## Why

Partner feeds break silently (bad encodings, missing fields, wrong dates) and corrupt the downstream pipeline; validation happens too late, after ingestion.

## Who

**Primary user:** A data engineer who babysits broken partner feeds every Monday.

Other potential users (deferred to later iterations):
- Partner-support staff reading quarantine reports (deferred).

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. A partner feed URL is registered with the service.
2. The service fetches the feed, validates it against a strict schema, and normalizes encodings and dates.
3. Clean feeds pass through to the pipeline; broken ones are quarantined with a precise error report.

**Success looks like:** A malformed feed is quarantined with an actionable error report instead of reaching the pipeline, and a clean feed passes through unchanged.

**Riskiest assumption** (test this first): The set of real-world feed defects can be covered by a strict schema plus a small set of normalizers, without per-partner special cases.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** A well-formed feed passes validation and is forwarded byte-identical.
- [ ] **REQ-AC2:** A feed with a wrong date format is quarantined with the offending field and line in the report.
- [ ] **REQ-AC3:** A feed with a non-UTF-8 encoding is normalized to UTF-8 and passed through.
- [ ] **REQ-AC4:** Quarantine events are visible via a status endpoint.

## Stack

- **Language:** Go 1.25+
- **Package manager:** go mod
- **Quality-gate command:** bash scripts/qa.sh
- **Test runner:** go test
- **Lint / format / type-check tools:** golangci-lint / gofmt / go build
- **Frontend:** no
- **Backend framework:** stdlib net/http
- **Database / persistence:** Postgres
- **Vector store:** none
- **LLM provider:** none
- **Embeddings model:** none
- **Dev container:** yes
- **Deployment target:** Internal service in the company Kubernetes cluster.
- **Scale expectations (first iteration):** About 200 partner feeds polled every 15 minutes; single instance is enough for the first iteration.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- Partner RSS/Atom feed endpoints (fetch).
- The internal ingestion pipeline's intake queue (forward).
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): yes
- **Holds private data** (user records, secrets, anything non-public): no
- **Acts on the outside world** (sends, writes externally, side-effecting tools): no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No feed content transformation beyond encoding/date normalization.
- No partner-facing UI; engineers query the status endpoint.

## Constraints

- Time: One sprint (two weeks) to a deployable internal service.
- Cost: Runs on existing internal infrastructure; no new paid services.
- Data: Feeds are partner-owned content; quarantined copies are retained for 30 days then deleted.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
