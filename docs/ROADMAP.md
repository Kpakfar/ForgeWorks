# Roadmap

Where ForgeWorks is today, and what is deferred. Read this with the README
`## Status` section before judging what the tool does mechanically versus what
is still future work. The history of each release is in the git log.

## Current state

- **Architecture: core + profiles.** A generated project is
  `init-project/templates/core/` (language-free) plus exactly one
  `init-project/templates/profiles/<lang>/`. Python, TypeScript, Go, and Rust
  are complete, each verified green on the first run by root CI on the merged
  tree. "Other" is not built.
- **Generation is deterministic.** The agent runs the interview and writes an
  answers file; `init-project/render.py` renders the tree. Same answers, same
  bytes, locked by nine golden fixtures.
- **Two loops.** The inner loop builds one feature (GRILL, RED, GREEN, REVIEW)
  against programmatic checks with hard caps. The outer loop (REPLAN, since
  v5.2.0) asks before every merge whether the PRD, the next feature, and the
  dependency edges still hold, and its edits land with the feature.
- **The feature list is a graph.** `depends_on` edges are checked for unknown
  ids and cycles; `go` offers only a feature whose dependencies are done.
  Features with no edge between them can run in parallel worktrees.
- **Portability.** `AGENTS.md` and the skills travel to any agent (a Codex or
  Antigravity roster gets them linked at `.agents/skills`). Subagents, hooks, and MCP wiring run in
  Claude Code only.

- **The loop's edges are refused and recorded.** `scripts/feature.py` refuses
  a start before a dependency is done, a skipped phase, a GREEN with no cited
  test, a close that did not pass REVIEW, and a review past its counted cap.
  A refused edge opens with a reason that is recorded on the entry. The
  script cannot tell who typed the reason: that stays a rule until the
  owner-gate hook below exists.

## Next

- **Adopt an existing codebase (v5.3).** A separate `adopt-project` skill that
  derives the PRD, the stack, and the feature list from a repository
  ForgeWorks did not generate. Today `install.sh` stops in such a folder.
- **Re-run the gate inside `land.sh`.** A rebase can break a green branch;
  today `land.sh` only tells the session to run the gate again.
- **Enforce the owner gates by hook.** Since v5.2.0 a hard rule makes every
  hard-to-reverse action (deleting data, a destructive migration, push,
  publish, deploy, money) wait for the owner's yes. It is a rule the agent
  follows, not a mechanism. A `PreToolUse` hook that blocks the matching
  commands would make it one.
- **Count what the scripts cannot see yet.** The GREEN stall cap and the
  design-rework cap are still prose: no script observes a failed cycle. The
  `reviews` count and the `override:` notes are the first intervention
  record; a report over them (reviews per feature, overrides per release)
  would show where the loop needs the owner.
- **Unit-scoped correction.** A reviewer finding returns one unit with its
  scope stated, so a fix cannot grow into an unreviewed diff.

## Known limitations

- **Supply chain.** Actions are SHA-pinned, dev-container images are
  digest-pinned, the `uv` installer is checksum-verified, `degit` and the
  Context7 package are version-pinned. The npm runtime and degit's fetch
  integrity are trusted; the `deps-guard` hook is a best-effort guard, not a
  sandbox.
- **Enforcement parity.** Other agents inherit the rules, docs, skills, and
  roster. Adapters that reproduce the Claude Code subagents and hooks
  elsewhere are not built.
- **No unattended shipping.** Scheduled or overnight loops need scope,
  authority, budget, and restart rules that do not exist yet. The loop is
  built for an owner who approves the plan and reads the merge report.
- **The loop diagram** (`docs/forgeworks-loop.svg`) predates REPLAN.
- **A 5-minute worked example** is deferred.
