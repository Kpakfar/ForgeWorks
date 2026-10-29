# Documentation Index

This project uses **Context7 MCP** (wired up in `.mcp.json`) as the primary tool for live, version-specific library API lookups. Query Context7 first; fall back to direct `WebFetch` only if Context7 doesn't cover the library or returns nothing useful.

## How to use Context7

- Always query the **pinned version** in `Cargo.toml`, not "latest."
- Use for any library whose API may have shifted since training cutoff.
- If Context7 returns nothing useful, fall back to `WebFetch` and note the gap in `docs/gotchas.md`.
- Context7 is a hosted HTTP server (the URL is in `.mcp.json`), so nothing runs locally. An agent that does not read `.mcp.json` registers the same URL in its own MCP config.

## Library URLs

`/init-project` seeds this section with the library docs URLs relevant to your chosen stack. Add new entries here whenever a new library is introduced to the project.

### Core stack
- **The Rust Book**: https://doc.rust-lang.org/book/
- **Standard library**: https://doc.rust-lang.org/std/
- **The Cargo Book**: https://doc.rust-lang.org/cargo/
- **Clippy lint list**: https://rust-lang.github.io/rust-clippy/master/
- **rustfmt**: https://github.com/rust-lang/rustfmt
