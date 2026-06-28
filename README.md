# ForgeWorks

> One command turns an empty folder into a structured, TDD-driven, security-gated project — built for **agentic coding**.

It is not a starter app. It installs the rules, specialist roles, and deterministic gates that make an AI coding agent produce code you can actually review, ship, and maintain. The core is stack-agnostic; your language and tooling are chosen in a short interview, not hard-coded.

```bash
mkdir my-project && cd my-project && git init
bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v1.0.0/bootstrap/install.sh)
# then open your agent and run:  /init-project
```

## Why use it

- **Works with any agentic coder.** The whole constitution lives in `AGENTS.md` (symlinked to `CLAUDE.md`) — the cross-tool standard read by Claude Code, Codex, Cursor, opencode, and others. Any agent inherits the same rules, gates, and docs; the deep orchestration (subagents, hooks, MCP) runs in Claude Code today, and other agents ignore the Claude-specific parts gracefully.
- **Two agents, two perspectives.** Drive with your primary agent and bring a **second one as an independent reviewer** — e.g. **Codex** (opt in during setup) — for a genuine second opinion on important changes. Two models reviewing beats one.
- **Plans from the heart, not lazily.** A structured discovery — core flow, riskiest assumption, non-goals, named test plan, a proactive "what's missing?" pass — is signed off *before* any code.
- **The whole test pyramid, at spec time.** Unit + functional/API + headless-browser e2e + security tests are named in the plan and written first (Red phase).
- **Security is enforced, not requested.** Access-control/IDOR, secrets, supply chain, and (for AI apps) prompt-injection defenses live in `AGENTS.md` + `docs/SECURITY.md`, backed by a real `PreToolUse` supply-chain hook — because prompt-level security is theater.
- **Self-improving & upgradeable.** Lessons flow back into the template; existing projects pull updates with `/upgrade-project`, non-destructively.

## What you get

- **`AGENTS.md` constitution** — architecture, security, test, planning, and design (mockup-over-ASCII) discipline, all in one source of truth.
- **5 subagents** — `@test-spec-writer`, `@implementer`, `@code-reviewer` (+ optional Codex second opinion), `@security-reviewer`, `@tech-debt`.
- **Deterministic gates** — a verify-only `qa` (plus a local `fix`), a supply-chain `deps-guard` hook, and CI (fast gate + separate e2e job).
- **Living docs** — product vision, requirements, structure, gotchas, SECURITY, and a shared current-task scratchpad agents read and write.
- **Batteries** — Context7 MCP for live library docs, an optional dev container, a green-on-first-run scaffold, a PR template, and pre-commit config.

## How it works

The main agent orchestrates the loop; `tdd` and `grill-me` (from `mattpocock/skills`) drive the methodology and planning. Three subagents pair with the per-slice **Red → Green → Refactor → Review** loop; two more run on a recurring cadence. Sub-1h tasks skip the ceremony entirely. The same gate runs locally (a `Stop` hook that blocks a red build) and in CI.

## Upgrade an existing project

Run the **same command** inside it — `install.sh` detects a generated project and installs `/upgrade-project` instead of bootstrapping:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v1.0.0/bootstrap/install.sh)
# then run:  /upgrade-project
```

It reconciles your project against the current template — copying missing files and grafting new rule blocks **without overwriting your content**. Non-destructive and idempotent. (Never re-run `/init-project` on an existing project; that overwrites your filled-in docs.)

## Repo layout

```
bootstrap/        seed kit + install.sh (bootstraps empty dirs, routes existing ones to upgrade)
init-project/     /init-project skill — interview + generation; templates/core/ + templates/profiles/<lang>/
upgrade-project/  /upgrade-project skill — non-destructive reconcile for existing projects
docs/             how-to-use.md and the review/roadmap
VERSION           stamped into generated projects
```

## Languages

**Python, TypeScript, and Go** are complete profiles — pick any in the interview and the project is green on the first run, with only that language's toolchain (no cross-language leakage). Rust and "Other" aren't built yet (the interview tells you so and gets consent). Adding a language is a documented recipe (`docs/how-to-use.md`). Releases are pinned, immutable tags (current: `v1.0.0`).

## License

MIT. Use it, change it.
