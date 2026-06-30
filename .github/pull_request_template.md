<!-- See CONTRIBUTING.md and AGENTS.md before opening a PR. -->

## What & why

<!-- One or two sentences: what this changes and the reason. -->

## Type

- [ ] Fix
- [ ] Feature / new capability
- [ ] Docs
- [ ] Tooling / CI

## Checklist

- [ ] Conventional Commit title; no `Co-Authored-By` trailer.
- [ ] If it touches `init-project/SKILL.md` Phase 4, `templates/core/AGENTS.md` rule blocks, or `bootstrap/install.sh` — this is a reviewed PR (per `<conventions>`).
- [ ] Language-free `core/`; anything stack-specific lives in `templates/profiles/<lang>/`.
- [ ] Tested: root CI is green, and/or a throwaway bootstrap (`BRANCH=main`) was inspected.
- [ ] No new unresolved `{{PLACEHOLDER}}`; the `CLAUDE.md` symlink is intact.
