# {{PROJECT_NAME}}

{{PROJECT_GOAL}}

## Getting started

```bash
{{INSTALL_COMMAND}}      # install dependencies from the lockfile
{{QA_COMMAND}}           # run the quality gate (lint, format check, types, tests)
```

The scaffold ships a placeholder module and a passing test so the quality gate
is green from the first run. Replace them with your first feature.

## Commands

| Command | What it does |
|---|---|
| `{{QA_COMMAND}}` | Verify only: lint, format check, type check, unit + functional tests. Safe in CI. |
| `{{FIX_COMMAND}}` | Auto-repair locally: apply lint fixes and reformat. Review the diff, then commit. |
| `{{E2E_COMMAND}}` | Run the end-to-end suite. Separate from the fast gate. |

## How this project works

- `AGENTS.md` is the constitution -- read it first. `CLAUDE.md` symlinks to it.
- `docs/PRD.md` states the product; `docs/features.json` is the
  machine-checked feature list and the loop's state (`scripts/feature.py`
  reads or updates one entry), rendered into `docs/BACKLOG.md`.
- Each feature runs through the one iteration loop -- GRILL, RED, GREEN,
  REVIEW (one `@reviewer` pass), MERGE -- see the `iteration` skill. A plan
  lives in `docs/plans/` only while its feature is being built and is
  deleted at merge; its decisions land in `features.json` and the commit.

*Bootstrapped from [ForgeWorks](https://github.com/Kpakfar/ForgeWorks).*
