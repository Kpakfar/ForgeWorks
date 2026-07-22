# Product Vision: Linkcheck

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **A docs maintainer who keeps finding broken links after release.**
who **keeps finding broken links after release**,
Linkcheck is a **docs link checker CLI**
that **catches dead links locally before they ship**.
Unlike **clicking links by hand or a heavyweight CI service**,
we **one fast local command, no service to configure**.

## 5W answers

- **Who:** A docs maintainer who keeps finding broken links after release.
- **What:** A CLI that finds dead links in a Markdown docs folder before they ship.
- **Why:** Dead links are only discovered by readers; existing checkers are heavyweight CI services when a fast local CLI would do.
- **When:** none set
- **Where:** Local CLI installed from npm.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Markdown link extraction across a folder tree.
- Concurrent liveness checks with one retry.
- file:line reporting and a non-zero exit on failures.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No HTML or PDF scanning; Markdown only.
- No CI service or hosted dashboard; local CLI only.

## Business goals

Outcome + metric + target. Cap at three.

- scan time on 200 files -- under 30 seconds
- false positives per run -- zero on the reference docs tree

## Success looks like

> Running the CLI on a 200-file docs tree reports every dead link with file:line in under 30 seconds.

---

*Last updated: 2026-07-12*
