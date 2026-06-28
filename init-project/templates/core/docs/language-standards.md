# Language & tooling standards

Language- and tool-specific conventions for this project. Filled in by `/init-project` from your setup answers. Update this file whenever a tooling decision changes.

## Language

- **Language:** {{LANGUAGE}}
- **Version:** {{LANGUAGE_VERSION}}

## Package management

- **Package manager:** {{PACKAGE_MANAGER}}
- **Manifest file:** {{MANIFEST_FILE}}
- **Install dependencies:** `{{INSTALL_COMMAND}}`
- **Add a dependency:** `{{ADD_DEP_COMMAND}}`

Never bypass the package manager. Never install globally.

## Quality-gate toolchain

The bundled command `{{QA_COMMAND}}` **verifies only and changes no files**, so it is safe in CI. It chains the following, in order; each must pass for the gate to be green.

| Step | Tool | Command |
|---|---|---|
| Lint (check) | {{LINT_TOOL}} | `{{LINT_COMMAND}}` |
| Format (check) | {{FORMAT_TOOL}} | `{{FORMAT_COMMAND}}` |
| Type-check | {{TYPE_TOOL}} | `{{TYPE_COMMAND}}` |
| Tests (unit + functional) | {{TEST_RUNNER}} | `{{TEST_COMMAND}}` |

To auto-repair formatting and safe lint issues locally, run `{{FIX_COMMAND}}` -- the mutating counterpart -- then review the diff and commit. Never run `fix` in CI or a review hook: the gate must verify, not repair.

The end-to-end (headless-browser) suite is **not** in the fast gate. It runs separately via `{{E2E_COMMAND}}` in CI and pre-merge, so the inner TDD loop stays fast. e2e tests are marked `e2e` and live under `tests/e2e/`.

## Coding conventions

These are the conventions `@implementer` and `@code-reviewer` enforce alongside the language-agnostic rules in `AGENTS.md` `<architecture-discipline>`.

### Type annotations

{{TYPE_ANNOTATION_NOTES}}

### Imports

{{IMPORT_NOTES}}

### Async / concurrency

{{ASYNC_NOTES}}

### Error handling

{{ERROR_NOTES}}

### Config and secrets

{{CONFIG_NOTES}}

### Logging

{{LOGGING_NOTES}}

### Test layout and fixtures

{{TEST_LAYOUT_NOTES}}

## Pre-commit hooks

{{PRECOMMIT_HOOKS_NOTES}}

## Supply chain

New dependencies pass through the `deps-guard` PreToolUse hook (`.claude/hooks/deps-guard.sh`): it blocks installs of new/named packages until you confirm the package is real and established and will land in the committed lockfile, then re-run with `DEPS_VETTED=1` in front. Install from the lockfile only; no blind `latest`.

## CI

GitHub Actions runs the fast `{{QA_COMMAND}}` gate plus a separate end-to-end job (`{{E2E_COMMAND}}`). The shipped workflow triggers on **pull requests** and on **pushes to `main`** (see `.github/workflows/qa.yml`).

A red run does not block a merge by itself -- that requires **branch protection** on the repository (Settings -> Branches -> require the `QA` checks to pass). The template cannot configure that for you; enable it once the repo is on GitHub so a red CI actually blocks the merge.

---

*Last updated: {{DATE}}*
