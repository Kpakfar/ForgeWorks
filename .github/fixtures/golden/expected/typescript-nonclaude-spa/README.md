# Ledgerline

A web app that turns a freelancer's raw bank CSV export into a categorized income/expense ledger.

## Getting started

```bash
npm install      # install dependencies from the lockfile
npm run qa           # run the quality gate (lint, format check, types, tests)
```

The scaffold ships a placeholder module and a passing test so the quality gate
is green from the first run. Replace them with your first feature.

## Commands

| Command | What it does |
|---|---|
| `npm run qa` | Verify only: lint, format check, type check, unit + functional tests. Safe in CI. |
| `npm run fix` | Auto-repair locally: apply lint fixes and reformat. Review the diff, then commit. |
| `npm run e2e` | Run the end-to-end suite. Separate from the fast gate. |

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
