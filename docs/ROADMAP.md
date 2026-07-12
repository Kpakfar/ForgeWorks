# Roadmap

Where ForgeWorks is today, and what is genuinely deferred. This is the honest
companion to the README `## Status` section — read both before judging what the
tool does mechanically versus what is still future work.

## Current state

- **Architecture: core + profiles.** A generated project is `init-project/templates/core/`
  (language-free files: `AGENTS.md`, docs, security files, `.mcp.json`, CI shape)
  plus exactly one `init-project/templates/profiles/<lang>/`. No second language's
  files ever leak in.
- **Language profiles.** Python, TypeScript, Go, and Rust are complete profiles,
  each **verified green on the first run by the root CI** (`.github/workflows/ci.yml`),
  which renders the merged core+profile tree — the exact shape a generated
  project has — and runs the real quality gate and e2e runner on it.
  "Other" is not built — the interview says so and asks for consent
  before continuing.
- **Generation.** The interview and file substitution are driven by an AI agent
  following `init-project/SKILL.md`, in Claude Code today.
- **Portability.** The rules and docs (`AGENTS.md`, symlinked to `CLAUDE.md`) are
  the cross-tool standard and travel to any agent. The deep orchestration and
  local gates (subagents, hooks, MCP) run in Claude Code.

## Known limitations / roadmap

- **Generation is agent-driven, not a deterministic engine.** A deterministic
  renderer plus golden-fixture CI (assert the generated tree byte-for-byte) is
  future work. Today the agent is the engine.
- **Supply-chain pinning is partial.** The `deps-guard` hook is a best-effort
  guard, not a sandbox. Full SHA-pinning of GitHub Actions, container images, and
  installers (e.g. the `uv` installer by checksum) is future work. (The Context7
  MCP package is now pinned to a version.) The real controls today are lockfile
  review and CI scanning.
- **Cross-agent parity beyond `AGENTS.md` is future.** Other agents inherit the
  rules and docs, but dedicated adapters that reproduce the Claude Code subagents,
  hooks, and MCP orchestration elsewhere are not built.
- Conditional prototype/mockup-skill install at bootstrap (v2 spec section 7): deferred -- the visual-design baseline in the generated `<design-discipline>` block covers mockup quality without a skill dependency; revisit if a canonical prototype skill lands in the default pack.
