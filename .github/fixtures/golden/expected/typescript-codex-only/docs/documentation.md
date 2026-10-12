# Documentation Index

This project uses **Context7 MCP** (wired up in `.mcp.json`) as the primary tool for live, version-specific library API lookups. Query Context7 first; fall back to direct `WebFetch` only if Context7 doesn't cover the library or returns nothing useful.

## How to use Context7

- Always query the **pinned version** in `package.json`, not "latest."
- Use for any library whose API may have shifted since training cutoff.
- If Context7 returns nothing useful, fall back to `WebFetch` and note the gap in `docs/gotchas.md`.
- An agent that does not load `.mcp.json` gets the same lookups from the Context7 CLI: `npx -y ctx7@0.6.0 library <name>`, then `npx -y ctx7@0.6.0 docs <libraryId> "<question>"`.

## Library URLs

`/init-project` seeds this section with the library docs URLs relevant to your chosen stack. Add new entries here whenever a new library is introduced to the project.

### Core stack
- **TypeScript**: https://www.typescriptlang.org/docs/
- **Vitest**: https://vitest.dev/
- **ESLint (flat config)**: https://eslint.org/docs/latest/
- **typescript-eslint**: https://typescript-eslint.io/
- **Prettier**: https://prettier.io/docs/
- **Playwright**: https://playwright.dev/docs/intro
