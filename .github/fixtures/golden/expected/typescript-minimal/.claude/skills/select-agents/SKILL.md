---
name: select-agents
description: >
  Re-select which agentic coders drive this project. Probes what is actually
  installed, presents the same selection list as the setup interview (B13),
  and rewrites docs/agents.json + docs/agents.md. Use when an agent (Codex,
  Antigravity, Cursor, ...) was installed or removed mid-project, or when
  offload roles should change. Triggers: "/select-agents", "add codex",
  "update the agent roster".
---

# Select agents

Reconcile the project's agent roster with what is actually available.
This skill edits EXACTLY two files: `docs/agents.json` and `docs/agents.md`.
If either is missing or malformed, STOP and report -- do not half-write.

## Step 1: Probe availability

Run (do not guess):

```bash
for tool in claude codex agy antigravity cursor gemini; do
  command -v "$tool" >/dev/null 2>&1 && echo "installed: $tool"
done
```

Claude Code counts as installed when this session runs inside it.

## Step 2: Present the selection

Read the current `docs/agents.json`. Show the user the roster options --
`claude-code`, `codex`, `antigravity`, `cursor`, `other` -- each marked
installed / not installed from the probe plus its current enabled/disabled
state. Ask which agents to enable (multi-select; a not-installed selection is
recorded as `"planned"`). Then ask whether the default roles fit
(orchestrator / utility / second_opinion / heavy_batch -- see
`docs/agents.md` for definitions).

## Step 3: Rewrite the two files

- `docs/agents.json`: keep the shape
  `{"schema": 1, "agents": [{"name": ..., "status": "installed"|"planned", "roles": [...]}]}`
  (2-space indent, sorted keys, trailing newline).
- `docs/agents.md`: regenerate the `## Roster` section from the canonical
  per-agent texts below -- one section per enabled agent, appending the
  planned-status blockquote for `"planned"` entries. Leave everything above
  `## Roster` untouched.

Canonical per-agent sections (keep in sync with the template's
`templates/conditional/agents/*.md`):

### Claude Code

Reads `AGENTS.md` (via the `CLAUDE.md` symlink) and gets the FULL enforcement
stack: the subagent roster under `.claude/agents/` (including the haiku-pinned
`@utility` for cheap mechanical work), the `PreToolUse`/`Stop` hooks under
`.claude/hooks/`, `.claude/settings.json`, MCP servers from `.mcp.json`, and
the `/select-agents` skill. Default roles: orchestrator, utility,
second_opinion, heavy_batch.

### Codex

Reads `AGENTS.md` (the cross-tool standard) -- rules and docs apply; the
Claude-specific enforcement (subagents, hooks) does not. Usable from any
driver as a dispatch target: `codex exec "<task brief>"` for second-opinion
reviews and heavy batch work. Default roles: second_opinion, heavy_batch.

### Antigravity

Reads `AGENTS.md` -- rules and docs apply; Claude-specific enforcement
(subagents, hooks) does not. Use it as a dispatch target for heavy batch work
and independent reviews when it is installed. Default roles: second_opinion,
heavy_batch.

### Cursor

Reads `AGENTS.md` -- rules and docs apply; Claude-specific enforcement
(subagents, hooks) does not. Best used interactively for an independent
second perspective on important changes. Default role: second_opinion.

### Other agent

Reads `AGENTS.md` if it supports the cross-tool standard; rules and docs
apply, enforcement does not. Assign roles by editing `docs/agents.json` once
you know what the tool can do. Default roles: none.

## Step 4: Report

Summarize the before/after roster and remind the user: rules read the JSON at
runtime, so the change is already live; no re-render is needed.
