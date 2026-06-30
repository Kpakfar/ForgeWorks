# Contributing to ForgeWorks

The full developer guide is **`AGENTS.md`** (symlinked to `CLAUDE.md`) — read it
first. It is the constitution for working *on* the template. This file is the
short version.

## How the repo is laid out

A generated project is `init-project/templates/core/` (language-free files) plus
exactly one `init-project/templates/profiles/<lang>/`. Anything language-specific
(manifest, toolchain, scaffold, dev container, `.gitignore`, pre-commit) lives in
the profile; `core/` must work for every language. See `AGENTS.md`
`<repo-architecture>` and `<editing-the-template>`.

## Pull requests

- **Conventional Commits** (`feat(template):`, `refactor(skill):`, `docs(readme):`).
  No `Co-Authored-By` trailer.
- **Open a PR** (not a direct push to `main`) for anything touching
  `init-project/SKILL.md` Phase 4, `init-project/templates/core/AGENTS.md` rule
  blocks, or `bootstrap/install.sh`. Trivial doc/typo edits can go straight to
  `main`.

## Testing a change

The template can't be unit-tested; bootstrap a throwaway project and inspect what
landed. In an empty directory outside this repo:

```bash
mkdir /tmp/forgeworks-smoke && cd /tmp/forgeworks-smoke && git init
BRANCH=main bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/main/bootstrap/install.sh)
# open Claude Code, run /init-project, walk the interview, inspect the tree.
```

`BRANCH=main` overrides the pinned release tag so you test your unreleased edits.
Full procedure: `AGENTS.md` `<testing-changes>`.

## Adding a language profile

A new profile must meet the same readiness contract as Python/TypeScript/Go: a
manifest, a verify-only `qa` runner plus separate `fix` and `e2e` runners, a
**green-on-first-run scaffold**, `.gitignore`, a hardened dev container, a YAML
block in `SKILL.md` `<language-profiles>`, and a Q3 menu entry marked `[complete]`
only once a bootstrapped project is green on the first run. Full contract:
`AGENTS.md` `<adding-a-language-profile>`.
