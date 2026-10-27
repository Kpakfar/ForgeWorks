# Agent roster and offload map

Which agentic coders drive this project, what each one actually gets, and
where work should be offloaded. Two files carry this:

- **`docs/agents.json`** -- the machine-readable roster (this doc's source of
  truth). It is a RUNTIME config: edit it directly. Rules in
  `AGENTS.md` read the roster from the JSON, so a change applies immediately --
  no re-render, no re-bootstrap.
- **This file** -- the human-readable matrix below.

Offload roles (the `roles` array in the JSON):

- `orchestrator` -- drives the loop, dispatches work, holds the gates.
- `utility` -- cheap-tier mechanical work (git housekeeping, log mining, bulk
  renames, doc formatting, status summaries).
- `second_opinion` -- independent review of important changes.
- `heavy_batch` -- large batch work (broad audits, big migrations, long
  test-fix loops), especially when the primary agent nears session limits.

**Workload shifting:** there is no API for "how much quota is left." When the
primary agent's harness shows usage-limit warnings, or a task is heavy batch
work, dispatch it to an installed `heavy_batch` agent from the roster and keep
the primary agent as orchestrator/reviewer -- shifting progressively more work
over as limit pressure grows.

## Roster

### Codex

Reads `AGENTS.md` (the cross-tool standard) -- rules and docs apply; the
Claude-specific enforcement (subagents, hooks) does not. Discovers the
project skills through `.agents/skills` (a link to `.claude/skills/`). Usable from any
driver as a dispatch target: `codex exec "<task brief>"` for second-opinion
reviews and heavy batch work. Default roles: second_opinion, heavy_batch.

### Enforcement omitted (no Claude Code in this roster)

This project was generated without the Claude Code enforcement stack: no
subagents (`.claude/agents/`, including the mandatory `@reviewer` and
`@utility`), no hooks (including the `deps-guard` supply-chain guard and the
quality-gate `Stop` hook), and no `.claude/settings.json` or `CLAUDE.md`
symlink. Where `AGENTS.md`, `docs/SECURITY.md`, or `docs/language-standards.md`
mandate a subagent or hook, treat the mandate as a manual responsibility of the
driving agent -- nothing replaces that automation today.

What DOES still ship: the skills under `.claude/skills/` (`iteration`,
`security-review`, and `tech-debt`). A Codex or Antigravity roster also gets
them linked at `.agents/skills`, where those agents discover skills. An agent
that discovers neither path reads and follows them as plain markdown. In particular, the security review
trigger (when a change needs a security pass) lives in
`.claude/skills/security-review/SKILL.md`, not in a subagent. Keep
`docs/features.json` and `docs/agents.json` current by hand.
