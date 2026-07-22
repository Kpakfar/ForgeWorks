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
- **Generation is deterministic (since v2.3.0).** The agent runs the interview
  and writes `docs/_init-answers.json`; `init-project/render.py` (stdlib
  Python, plain string substitution) renders the tree — every placeholder,
  conditional rule, structured-file escape, symlink, chmod, and version stamp.
  Same answers, same bytes. A golden-fixture CI job
  (`.github/scripts/golden_test.py`) compares six rendered answer sets —
  including a hostile-values fixture — byte-for-byte against committed
  expected trees. Only the interview itself and the package-manager dependency
  steps remain agent-executed.
- **Portability.** The rules and docs (`AGENTS.md`, symlinked to `CLAUDE.md`) are
  the cross-tool standard and travel to any agent. The deep orchestration and
  local gates (subagents, hooks, MCP) run in Claude Code.

## Known limitations / roadmap

- **Supply-chain pinning is largely done (v2.4.0).** GitHub Actions are
  SHA-pinned (with a CI job asserting it), dev-container base images are
  digest-pinned, the `uv` installer is sha256-verified, and `degit` and the
  Context7 MCP package are version-pinned. Remaining softness: the npm/npx
  runtime itself and degit's fetch integrity are trusted; the `deps-guard`
  hook stays a best-effort guard, not a sandbox.
- **Cross-agent parity beyond rules + roster is future.** Since v2.5.0 the
  interview selects the project's agent roster (B13), emits it as a runtime
  config (`docs/agents.json` + `docs/agents.md`), and ships `/select-agents`
  for mid-project changes. Other agents inherit the rules, docs, and roster;
  dedicated adapters that reproduce the Claude Code subagents, hooks, and MCP
  orchestration elsewhere are still not built.
- Conditional prototype/mockup-skill install at bootstrap (v2 spec section 7): deferred -- the visual-design baseline in the generated `<design-discipline>` block covers mockup quality without a skill dependency; revisit if a canonical prototype skill lands in the default pack.
- **Express/starter mode** (a lighter on-ramp with fewer gates) is deferred;
  positioning is honest-copy-only for now.
- **A 5-minute worked example** ("watch it build one real feature" walkthrough
  doc) is deferred.
