### Claude Code

Reads `AGENTS.md` (via the `CLAUDE.md` symlink) and gets the FULL enforcement
stack: the subagent roster under `.claude/agents/` (including the haiku-pinned
`@utility` for cheap mechanical work), the `PreToolUse`/`Stop` hooks under
`.claude/hooks/`, `.claude/settings.json`, MCP servers from `.mcp.json`, and
the `/select-agents` skill. Default roles: orchestrator, utility,
second_opinion, heavy_batch.
