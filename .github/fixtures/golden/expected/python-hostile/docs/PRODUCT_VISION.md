# Product Vision: Hostile "Fixture" & <Sons>, Ltd. `v0`

The north star for this project. Captures the *what* and *why*. Stable across iterations.

For the *how* (current sprint scope, stack, acceptance criteria), see `requirements.md`.
For the *when* (active queued work), see `backlog.md`.

---

## Positioning (Geoffrey Moore)

For **A user who types "quotes" & <angle brackets> into every form field they meet.**
who **watches renderers choke on "ordinary" punctuation & symbols**,
Hostile "Fixture" & <Sons>, Ltd. `v0` is a **renderer stress fixture**
that **proves hostile text lands verbatim as text, never as structure**.
Unlike **hoping users never type quotes**,
we **it is the test, not the product**.

## 5W answers

- **Who:** A user who types "quotes" & <angle brackets> into every form field they meet.
- **What:** A "goal" with 'single quotes',
an escaped newline, {{lowercase braces}}, `backticks`, & ampersands — plus a trailing backslash \ and a $dollar.
- **Why:** Systems break when text contains {{curly}} braces, `ticks`, "quotes",
or newlines; this fixture proves the renderer does not.
- **When:** none set
- **Where:** CI only — never deployed.
- **How:** see the core flow in `docs/requirements.md`

## Scope

**In scope** -- what v1 will do:

- Hostile values in every free-text answer field.
- Structured-file escaping (TOML & JSON) and prose passthrough.

**Out of scope (non-goals)** -- what it deliberately will NOT do:

- No attempt to sanitize or prettify hostile text; it must land verbatim.
- No support for text containing HTML comment markers (validated out).

## Business goals

Outcome + metric + target. Cap at three.

- structured-file parse failures -- zero
- hostile characters altered in prose -- zero

## Success looks like

> All rendered JSON/TOML files parse; the hostile strings land verbatim in Markdown, escaped in structured files.

---

*Last updated: 2026-07-12*
