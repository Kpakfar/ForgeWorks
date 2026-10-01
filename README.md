# ForgeWorks

> One command turns an empty folder into a structured, TDD-driven, security-gated project — built for **agentic coding**.

**Senior-team discipline for your AI coding agent.** You bring the idea plus working development and agentic-coding experience -- ForgeWorks wraps your agent in a senior team's discipline (planning, a real test pyramid, a security review, a second-opinion reviewer), so a solo developer can turn a prompt into a product that is actually tested, secure, and shippable -- not a throwaway demo. (If you have never driven an AI coding agent before, expect a learning curve: the machine enforces the quality gate, the feature-list check, and reviews scaled to risk.)

It is not a starter app. It installs the rules, specialist roles, and deterministic gates that make an AI coding agent produce code you can actually review, ship, and maintain. The core is stack-agnostic; your language and tooling are chosen in a short interview, not hard-coded.

```bash
mkdir my-project && cd my-project && git init
bash <(curl -fsSL https://raw.githubusercontent.com/kp-multiverse/ForgeWorks/v5.1.0/bootstrap/install.sh)
# then open your agent and run:  /init-project
```

## Why use it

- **Portable rules; enforcement is Claude Code today.** The whole constitution lives in `AGENTS.md` (symlinked to `CLAUDE.md`) — the cross-tool standard read by Claude Code, Codex, Cursor, opencode, and others. The rules and docs (`AGENTS.md`) are portable to any agent; the deep orchestration and local gates (subagents, hooks, MCP) run in Claude Code today, and other agents ignore the Claude-specific parts gracefully.
- **Two agents, two perspectives.** Drive with your primary agent and bring a **second one as an independent reviewer** — e.g. **Codex** (opt in during setup) — for a genuine second opinion on important changes. Two models reviewing beats one.
- **Ceremony sized to change, not to habit.** Two tiers — chore or feature — set how much ceremony a change needs, from "just build it and keep the gate green" to a full GRILL → RED → GREEN → REVIEW → MERGE loop with an owner-approved plan. UI-heavy features get a real mockup to approve *before* implementation.
- **The whole test pyramid, at spec time.** Unit + functional/API + headless-browser e2e + security tests are named in the plan and written first (RED phase) for feature-tier work.
- **Security is enforced, not requested.** Access-control/IDOR, secrets, supply chain, and (for AI apps) prompt-injection defenses live in `AGENTS.md` + `docs/SECURITY.md`, backed by a real `PreToolUse` supply-chain hook (a best-effort guard, not a sandbox) — because prompt-level security is theater.
- **Self-improving & upgradeable.** Lessons flow back into the template; existing projects pull updates with `/upgrade-project`, non-destructively.

## What you get

- **`AGENTS.md` constitution** — a hard-capped 100-line core (project, commands, hard rules, tiers, roster) that stays the single source of truth, plus on-demand skills for the iteration loop and security discipline for the ceremony that doesn't need to live on every page.
- **2 subagents** — `@reviewer` (the single fresh-context REVIEW pass — plan conformance, correctness, design fidelity, and security in one lens set, + optional Codex second opinion) and `@utility` (haiku-pinned, for mechanical chores that should never burn expensive-model tokens). There is no implementer subagent — main context drives GRILL and GREEN itself.
- **Skills** — `iteration` (the one per-feature workflow: GRILL -> RED -> GREEN -> REVIEW -> MERGE, chores skip straight to green), `security-review` (the trigger + procedure), and `tech-debt` (on-demand sweep).
- **Deterministic gates** — a verify-only `qa` (plus a local `fix`), a supply-chain `deps-guard` hook, a `features.json`/`features_check.py` feature-list check, a `docs-budget` doc-size check (including the `AGENTS.md` character cap), a test-tamper guard, a `skills_doctor.py` instruction-stack check (one copy per skill name, no always-on SessionStart plugin, the real session-start inventory), and CI (fast gate + separate e2e job).
- **A tree per session** — run several agent sessions on one project at once. The first session writes the main checkout; the `tree-claim` hook sends every later one into its own git worktree, and `bash scripts/land.sh` puts its commits back on the base branch (rebase, then fast-forward; conflicts stop in the session that caused them). `scripts/factory_doctor.sh` lists the trees that are safe to remove.
- **Living docs** — `docs/PRD.md`, the feature list (`docs/features.json`) with its human-readable `docs/BACKLOG.md` view, design docs, gotchas, and SECURITY. The loop's state (phase, next action, deviations) lives in each feature's entry, read and written by `scripts/feature.py`.
- **Batteries** — Context7 MCP for live library docs, an optional dev container, a green-on-first-run scaffold, a PR template, and a pre-commit config (Python profile only).

## How it works

A short conversation (at most 5 questions) drafts `docs/PRD.md`, the owner approves it, and the renderer generates the project. From there the `iteration` skill is the only per-feature workflow: chores build straight through the quality gate, features run GRILL -> RED -> GREEN -> REVIEW -> MERGE with hard caps, driven by `tdd` and `grill-me` (from `mattpocock/skills`). `@reviewer` runs the one REVIEW pass in fresh context — plan conformance, correctness, design fidelity (mockup diff, frontend projects), and security (on the canonical trigger) — in the same pass. Tasks with no behavioral effect (typos, doc wording, formatting) skip the ceremony — anything that changes what the product does, however small, does not. The same quality gate runs locally (a `Stop` hook that blocks a red build) and in CI.

![The ForgeWorks bounded iteration loop: a one-time bootstrap session, then a repeating five-step cycle (GRILL, RED, GREEN, REVIEW, MERGE) driven by the main agent with two subagents, priced dispatch, project weight, and deterministic gates](docs/forgeworks-loop.svg)

## Upgrade an existing project

Run the **same command** inside it — `install.sh` detects a generated project and installs `/upgrade-project` instead of bootstrapping:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kp-multiverse/ForgeWorks/v5.1.0/bootstrap/install.sh)
# then run:  /upgrade-project
```

It reconciles your project against the current template — copying missing files and grafting new rule blocks **without overwriting your content**. Non-destructive and idempotent. (Never re-run `/init-project` on an existing project; that overwrites your filled-in docs.)

## Repo layout

```
bootstrap/        seed kit + install.sh (bootstraps empty dirs, routes existing ones to upgrade)
init-project/     /init-project skill — interview + generation; templates/core/ + templates/profiles/<lang>/
upgrade-project/  /upgrade-project skill — non-destructive reconcile for existing projects
docs/             how-to-use.md and ROADMAP.md
VERSION           stamped into generated projects
```

## Languages

**Python, TypeScript, Go, and Rust** are complete profiles — pick any in the interview and you get only that language's toolchain (no cross-language leakage). All four are verified green on the first run by CI, on the **merged core+profile tree** (the exact shape a generated project has). "Other" isn't built yet (the interview tells you so and gets consent). Adding a language is a documented recipe (`docs/how-to-use.md`). Releases are versioned tags (current: `v5.1.0`): a pinned tag gives you the same template files tomorrow, though runtime inputs (npm/degit/Context7) aren't fully reproducible yet — see `docs/ROADMAP.md`.

## Status

ForgeWorks is an opinionated harness — a capable product with a clear roadmap. Be aware of what is and isn't mechanically true today:

- **Generation is deterministic.** The agent interviews you and writes an answers file; a stdlib-Python renderer (`init-project/render.py`) turns it into the project tree — same answers, same bytes, locked by golden-fixture CI (nine answer sets, byte-for-byte against committed expected trees, hostile values included). Only the interview itself and dependency installs remain agent work.
- **The supply-chain guard is best-effort.** The `deps-guard` hook reduces risk; it is not a sandbox. The real controls are lockfile review and CI scanning.
- **Profiles:** Python, TypeScript, Go, and Rust are each verified green in CI on the merged core+profile tree, quality gate and e2e runner included.

## License

MIT. Use it, change it.
