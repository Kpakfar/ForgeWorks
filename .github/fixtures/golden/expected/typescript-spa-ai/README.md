# Briefly

A web app that turns a team's weekly activity into a two-paragraph stakeholder brief.

## Getting started

```bash
npm install      # install dependencies from the lockfile
npm run qa           # run the quality gate (lint, format check, types, tests)
```

The scaffold ships a placeholder module and a passing test so the quality gate
is green from the first run. Replace them with your first slice.

## Commands

| Command | What it does |
|---|---|
| `npm run qa` | Verify only: lint, format check, type check, unit + functional tests. Safe in CI. |
| `npm run fix` | Auto-repair locally: apply lint fixes and reformat. Review the diff, then commit. |
| `npm run e2e` | Run the end-to-end suite. Separate from the fast gate. |

## How this project works

- `AGENTS.md` is the constitution -- read it first. `CLAUDE.md` symlinks to it.
- `docs/` holds the living documentation: product vision, requirements, structure,
  gotchas, security threat model, and the current-task scratchpad.
- Development runs through the TDD loop with specialist subagents; see
  `AGENTS.md` `<agent-roster>`.

*Bootstrapped from [ForgeWorks](https://github.com/Kpakfar/ForgeWorks).*
