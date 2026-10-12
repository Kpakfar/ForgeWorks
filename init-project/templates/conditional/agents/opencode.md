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
