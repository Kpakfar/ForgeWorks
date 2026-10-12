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
