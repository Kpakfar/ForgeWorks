# Chunkline

A Rust library that splits large text files into stable, overlap-aware chunks for indexing pipelines.

## Getting started

```bash
cargo fetch      # install dependencies from the lockfile
bash scripts/qa.sh           # run the quality gate (lint, format check, types, tests)
```

The scaffold ships a placeholder module and a passing test so the quality gate
is green from the first run. Replace them with your first slice.

## Commands

| Command | What it does |
|---|---|
| `bash scripts/qa.sh` | Verify only: lint, format check, type check, unit + functional tests. Safe in CI. |
| `bash scripts/fix.sh` | Auto-repair locally: apply lint fixes and reformat. Review the diff, then commit. |
| `bash scripts/e2e.sh` | Run the end-to-end suite. Separate from the fast gate. |

## How this project works

- `AGENTS.md` is the constitution -- read it first. `CLAUDE.md` symlinks to it.
- `docs/` holds the living documentation: product vision, requirements, structure,
  gotchas, security threat model, and the current-task scratchpad.
- Development runs through the TDD loop with specialist subagents; see
  `AGENTS.md` `<agent-roster>`.

*Bootstrapped from [ForgeWorks](https://github.com/Kpakfar/ForgeWorks).*
