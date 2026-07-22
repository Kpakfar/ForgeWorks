# Requirements: Linkcheck

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

A CLI that finds dead links in a Markdown docs folder before they ship.

## Why

Dead links are only discovered by readers; existing checkers are heavyweight CI services when a fast local CLI would do.

## Who

**Primary user:** A docs maintainer who keeps finding broken links after release.

Other potential users (deferred to later iterations):
- none identified yet

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. The maintainer runs the CLI against a docs folder.
2. The CLI scans every Markdown file and collects links.
3. It reports dead links with file and line, exiting non-zero when any are found.

**Success looks like:** Running the CLI on a 200-file docs tree reports every dead link with file:line in under 30 seconds.

**Riskiest assumption** (test this first): Concurrent HTTP checking is reliable enough to avoid false positives from rate-limited hosts.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** Running against a folder with one dead link exits non-zero and prints the link with file:line.
- [ ] **REQ-AC2:** A fully healthy docs tree exits zero with a one-line summary.
- [ ] **REQ-AC3:** Unreachable-host timeouts are retried once before being reported.

## Stack

- **Language:** TypeScript Node 22 (LTS) / TypeScript 5.7+
- **Package manager:** npm
- **Quality-gate command:** npm run qa
- **Test runner:** vitest
- **Lint / format / type-check tools:** eslint / prettier / tsc
- **Frontend:** no
- **Backend framework:** none (CLI/library)
- **Database / persistence:** none
- **Vector store:** none
- **LLM provider:** none
- **Embeddings model:** none
- **Dev container:** no
- **Deployment target:** Local CLI installed from npm.
- **Scale expectations (first iteration):** Single user, docs trees up to a few thousand files.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- none
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): no
- **Holds private data** (user records, secrets, anything non-public): no
- **Acts on the outside world** (sends, writes externally, side-effecting tools): no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No HTML or PDF scanning; Markdown only.
- No CI service or hosted dashboard; local CLI only.

## Constraints

- Time: Two-weekend side project.
- Cost: No paid services; free tooling only.
- Data: Only the user's local docs folder is read; nothing is uploaded.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
