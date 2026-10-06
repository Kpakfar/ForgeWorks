# Pillarwatch

A self-hosted status page that shows the up/down history of a small team's own services, no third-party dependency.

## Getting started

```bash
go mod download      # install dependencies from the lockfile
bash scripts/qa.sh           # run the quality gate (lint, format check, types, tests)
```

The scaffold ships a placeholder module and a passing test so the quality gate
is green from the first run. Replace them with your first feature.

## Commands

| Command | What it does |
|---|---|
| `bash scripts/qa.sh` | Verify only: lint, format check, type check, unit + functional tests. Safe in CI. |
| `bash scripts/fix.sh` | Auto-repair locally: apply lint fixes and reformat. Review the diff, then commit. |
| `bash scripts/e2e.sh` | Run the end-to-end suite. Separate from the fast gate. |

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
