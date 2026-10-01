# What the renderer does

Reference for template maintainers. `render.py` is the canonical
implementation, locked byte-for-byte by the golden fixtures in the template
repo's CI; this table documents its rules from the answers file. The agent
running `/init-project` does not execute any of this by hand.

| # | Rule (from the answers) |
|---|---|
| 1 | Substitutes every placeholder in the tables below (core + the chosen profile only), re-indenting multi-line values to the placeholder's own column so YAML stays valid. |
| 2 | Escapes free-text answers per target format: JSON-escaped in `.json`, TOML-escaped in `.toml`, verbatim in Markdown/text -- hostile quotes/newlines/braces land as text, never as structure. Free text in any other file type is a hard error. |
| 3 | AI features selected -> renders `{{AI_DISCIPLINE_BLOCK}}` from `templates/conditional/ai-discipline.md`; none -> empty. |
| 4 | AI fences: AI on -> strips only the marker lines and keeps the content; AI off -> deletes the whole fenced blocks in `docs/SECURITY.md` (AI-SECURITY, AI-REDTEAM), `.claude/agents/reviewer.md` (AI-REVIEW). |
| 5 | Style references: renders the positive/negative codebase-shape reference lines, or the "no positive reference yet" comment / empty string. |
| 6 | `opt_ins.explanations: no` -> `docs/explanations/` is not generated. |
| 7 | `opt_ins.seed_gotchas: yes` -> inserts the three starter entries from `templates/conditional/gotchas-seed.md` into `docs/gotchas.md`. |
| 8 | `opt_ins.mem0: yes` -> keeps `docs/memory.md`, renders `{{MEMORY_DOC_LINE}}` in `AGENTS.md`'s `<project>` block, and inserts the `<memory>` block (from `templates/conditional/memory-block.md`, see rule 21 for the anchor); `no` -> none of those. The `mem0ai` dependency itself is added in Phase 4.5. |
| 9 | `opt_ins.codex_reviewer: yes` -> renders `{{CODEX_REVIEW_STEP}}` and `{{CODEX_ROSTER_NOTE}}` from `templates/conditional/codex-*.md`; `no` -> both empty. |
| 10 | Seeds the security-profile line into `docs/SECURITY.md` from the `security` answers; if all three are `yes` AND AI features are on, appends the lethal-trifecta-PRESENT note to that same insertion. |
| 11 | `stack.uses_devcontainer: no` -> `.devcontainer/` is not generated. |
| 12 | `stack.has_frontend` + profile: renders `{{E2E_BROWSER_INSTALL_STEP}}` as the browser-install step (UI project with a profile `e2e_browser_install`) or the "no browser needed" comment. |
| 13 | Renames profile manifests shipped with an `.example` suffix (`pyproject.toml.example` -> `pyproject.toml`). Core files are never renamed (`.env.example` stays). |
| 14 | Creates the `CLAUDE.md` -> `AGENTS.md` symlink (a one-line pointer file where symlinks are unavailable), `chmod +x` on `.claude/hooks/*.sh` and `scripts/*.sh`, and stamps `.claude/.template-version` (with this release's version) if the bootstrap `install.sh` did not already write it. |
| 15 | Fails closed if any `{{...}}` placeholder survives anywhere in the output. |
| 16 | When `claude-code` is NOT in `agents`, `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, `.worktreeinclude`, and the `CLAUDE.md` symlink are not generated -- these are the Claude-specific enforcement mechanics (subagents, hooks, settings). `.claude/skills/` (`iteration`, `security-review`, `tech-debt`) ships regardless of roster: they are plain-markdown procedures any driving agent can read and follow, not Claude Code slash commands. `.claude/.template-version` is likewise always written by post-processing (rule 14) regardless of roster. A `claude-code` entry with `"status": "planned"` still counts as selected for this rule -- the agents/hooks/settings tree is still generated; `status` only affects `docs/agents.json` and the matrix status note (rule 17). |
| 17 | Renders `{{AGENT_MATRIX}}` in `docs/agents.md` from `templates/conditional/agents/<name>.md` (planned agents get a status note) and writes the machine-readable roster `docs/agents.json` (name, status, offload roles). When `claude-code` is NOT in `agents`, an honest-omission note (`templates/conditional/agents/no-claude-note.md`) is appended as the final section of `docs/agents.md`, spelling out what was skipped and that `docs/SECURITY.md` / `docs/language-standards.md` mandates -- and keeping `docs/features.json` current -- fall to the driving agent manually. |
| 18 | CC fences (same mechanic as AI fences, rule 4, keyed on "claude-code in `agents`" instead of `ai_features`): claude-code present -> strips only the marker lines; absent -> deletes the whole fenced block. Current instance: `<!-- CC-HOOKS-START/END -->` around the deps-guard hook bullet in `docs/SECURITY.md`'s Enforcement section (the hook is a Claude Code enforcement mechanic, so other rosters do not get the bullet). |
| 19 | Writes `docs/features.json` from the answers' `features` list (schema 1) and `docs/agents.json` from the roster; `docs/BACKLOG.md` ships as a static file until the first merge regenerates it via `scripts/prune.py`. |
| 20 | Frontend projects: renders `docs/design/` (DESIGN.md + mockups/) and the profile tokens.css; `has_frontend: no` skips both (skip_file rule). There is no separate design agent or skill in v4.0.0 -- design fidelity is one of `@reviewer`'s four lenses, checked at the REVIEW step of the `iteration` skill, not a dedicated pass. |
| 21 | mem0 memory block inserts after `<!-- /FW-BLOCK: learning -->`. |
| 22 | `AGENTS.md` is size-capped (characters) after every substitution and insertion; the renderer raises if the rendered file exceeds the cap, the same number the generated `docs-budget` job enforces. |
| 23 | `weight`: lite fences (`# FW-LITE-START/END`, YAML-comment markers -- same mechanic as rules 4/18) keep their lines only when `weight` is `lite`: the release-tag e2e trigger + job `if:` and the advisory dup gate in `qa.yml`. `docs/agents.json` gains `weight` and `model_tiers` (the dispatch ladder: `mechanical`/`standard`/`judgment` -- concrete model ids for a Claude roster, owner-filled TODOs otherwise; model ids live only there, never in prose). A tier value may carry a harness prefix (`opencode:<model-id>`) to route that tier through another roster harness's non-interactive runner, and may be an ordered list of channels (spend order, free before paid -- the iteration skill's channel-economy rule defines the sideways spillover); a Claude+opencode roster defaults `standard` to a free-then-paid `opencode:` TODO chain so cheap-coder GREEN dispatches route through OpenCode once the owner fills the model ids. |

