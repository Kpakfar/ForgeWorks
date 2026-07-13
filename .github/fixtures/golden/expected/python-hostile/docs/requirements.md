# Requirements: Hostile "Fixture" & <Sons>, Ltd. `v0`

Positioning, business goals, and the 5W live in `docs/PRODUCT_VISION.md` (the
north star); this file owns the current iteration: criteria, stack, constraints.

## What

A "goal" with 'single quotes',
an escaped newline, {{lowercase braces}}, `backticks`, & ampersands — plus a trailing backslash \ and a $dollar.

## Why

Systems break when text contains {{curly}} braces, `ticks`, "quotes",
or newlines; this fixture proves the renderer does not.

## Who

**Primary user:** A user who types "quotes" & <angle brackets> into every form field they meet.

Other potential users (deferred to later iterations):
- none identified yet

## Core user flow (MVP) -- the heart of the project

The single flow this project must support well in the first iteration:

1. Feed the renderer text full of "quotes" & braces.
2. Render.
3. Every structured file still parses; every prose file carries the text verbatim.

**Success looks like:** All rendered JSON/TOML files parse; the hostile strings land verbatim in Markdown, escaped in structured files.

**Riskiest assumption** (test this first): Plain per-format escaping ({{braces}} included) is enough — no template engine needed.

## Acceptance criteria (MVP)

Derived from the core flow above. Numbered and observable -- these are the
**iteration-level** contract (REQ-AC1, REQ-AC2, ...). A slice's
`docs/current-task/task.md` has its own slice-scoped `AC1..n` that each cite the
`REQ-AC` they advance, and a test proves each. (Distinct numbering avoids confusing
iteration criteria with a slice's.)

- [ ] **REQ-AC1:** `pyproject.toml` parses with the hostile description "as-is" (escaped).
- [ ] **REQ-AC2:** `.devcontainer/devcontainer.json` parses with the hostile name & ampersand.
- [ ] **REQ-AC3:** Markdown docs carry quotes, `backticks`, {{braces}} and newlines verbatim.

## Stack

- **Language:** Python 3.12+
- **Package manager:** uv
- **Quality-gate command:** uv run qa
- **Test runner:** pytest
- **Lint / format / type-check tools:** ruff / ruff format / mypy
- **Frontend:** yes-minimal
- **Backend framework:** Streamlit/Gradio only
- **Database / persistence:** none
- **Vector store:** none
- **LLM provider:** none
- **Embeddings model:** none
- **Dev container:** yes
- **Deployment target:** CI only — never deployed.
- **Scale expectations (first iteration):** One render per CI run.
- **External systems / integrations (each requires a reality probe -- see `docs/probes/`):**
- none
- **CI:** GitHub Actions (`.github/workflows/qa.yml`)

Language- and tool-specific conventions are in `docs/language-standards.md`.

## Security profile (threat model)

From the setup interview (B8). Drives `docs/SECURITY.md` and the red-team tests.

- **Reads untrusted content** (web, uploads, third-party/tool results, inbound messages): yes
- **Holds private data** (user records, secrets, anything non-public): yes
- **Acts on the outside world** (sends, writes externally, side-effecting tools): no

If all three are true for a single LLM agent, the **lethal trifecta** is present. State here how the project breaks one leg (split the agent, drop a capability, or gate the action behind a human). Full threat model and defenses: `docs/SECURITY.md`.

## Out of scope (for now)

Things explicitly NOT in this iteration. Move from here to `proposals-ideas.md` if they become live ideas:

- No attempt to sanitize or prettify hostile text; it must land verbatim.
- No support for text containing HTML comment markers (validated out).

## Constraints

- Time: none — this is a CI fixture.
- Cost: none & nothing.
- Data: Only synthetic hostile strings; nothing real.

## Open questions

Track unresolved questions here. Resolve and move out as decisions get made.

- none yet -- add them as they appear; resolve and move out as decisions get made

---

*Last updated: 2026-07-12*
