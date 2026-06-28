# Documentation Index

This project uses **Context7 MCP** (wired up in `.mcp.json`) as the primary tool for live, version-specific library API lookups. Query Context7 first; fall back to direct `WebFetch` only if Context7 doesn't cover the library or returns nothing useful.

## How to use Context7

- Always query the **pinned version** in `{{MANIFEST_FILE}}`, not "latest."
- Use for any library whose API may have shifted since training cutoff.
- If Context7 returns nothing useful, fall back to `WebFetch` and note the gap in `docs/gotchas.md`.

## Library URLs

`/init-project` seeds this section with the library docs URLs relevant to your chosen stack. Add new entries here whenever a new library is introduced to the project.

{{LIBRARY_DOCS_URLS}}

## Notes for agents

- Always query Context7 first. Training-data memory will be off for fast-moving libraries.
- Some library APIs change frequently between minor versions. Verify before writing from memory.
- When a library's API changes between minor versions, capture the lesson in `docs/gotchas.md`.

---

*Add new entries here whenever a new library is introduced to the project.*
