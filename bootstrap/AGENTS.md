<!--
  BOOTSTRAP version of AGENTS.md. The init-project skill replaces this file
  with the project's own AGENTS.md when it runs.
-->

# AGENTS.md (Bootstrap Mode)

<bootstrap-mode>
This project is uninitialized: `docs/features.json`, `docs/PRD.md`, and
`.claude/agents/` do not exist yet.

1. Confirm with the user that they want to bootstrap this project.
2. Run `/init-project` (or read `.claude/skills/init-project/SKILL.md` and
   follow it). It interviews the user, then renders the project: an
   `AGENTS.md` constitution, the `iteration` / `security-review` / `tech-debt`
   skills, the `reviewer` and `utility` subagents with their hooks, `docs/`
   (PRD, feature list, threat model, gotchas), CI, and the chosen language's
   toolchain with a green-on-first-run scaffold.

Until bootstrap is complete: do not write code, create unrelated files, or
commit.
</bootstrap-mode>
