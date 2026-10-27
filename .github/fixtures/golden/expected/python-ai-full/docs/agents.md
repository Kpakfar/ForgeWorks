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

### Claude Code

Reads `AGENTS.md` (via the `CLAUDE.md` symlink) and gets the FULL enforcement
stack: the subagent roster under `.claude/agents/` (including the haiku-pinned
`@utility` for cheap mechanical work), the `PreToolUse`/`Stop` hooks under
`.claude/hooks/`, `.claude/settings.json`, MCP servers from `.mcp.json`, and
docs/agents.json for roster changes. Default roles: orchestrator, utility,
second_opinion, heavy_batch.

### Codex

Reads `AGENTS.md` (the cross-tool standard) -- rules and docs apply; the
Claude-specific enforcement (subagents, hooks) does not. Discovers the
project skills through `.agents/skills` (a link to `.claude/skills/`). Usable from any
driver as a dispatch target: `codex exec "<task brief>"` for second-opinion
reviews and heavy batch work. Default roles: second_opinion, heavy_batch.

### OpenCode

Reads `AGENTS.md` (the cross-tool standard) -- rules and docs apply; the
Claude-specific enforcement (subagents, hooks) does not. Discovers the
project skills in `.claude/skills/`. Model-agnostic
harness: fill `model_tiers` in `docs/agents.json` with its model ids
(`opencode models` lists them) -- a free/flash model for `mechanical`, a
strong cheap coding model for `standard`, a frontier model for `judgment`.
A tier may hold an ordered spend chain (free channel first, then paid);
see the `iteration` skill's dispatch reference.
Can drive the full `iteration` loop itself or take dispatched job cards
from any driver: `opencode run -m <model-id> "<job card>"` (non-interactive).
Default roles: orchestrator, second_opinion, heavy_batch.
