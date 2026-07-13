# Language & tooling standards

Language- and tool-specific conventions for this project. Filled in by `/init-project` from your setup answers. Update this file whenever a tooling decision changes.

## Language

- **Language:** TypeScript
- **Version:** Node 22 (LTS) / TypeScript 5.7+

## Package management

- **Package manager:** npm
- **Manifest file:** package.json
- **Install dependencies:** `npm install`
- **Add a dependency:** `npm install`

Never bypass the package manager. Never install globally.

## Quality-gate toolchain

The bundled command `npm run qa` **verifies only and changes no files**, so it is safe in CI. It chains the following, in order; each must pass for the gate to be green.

| Step | Tool | Command |
|---|---|---|
| Lint (check) | eslint | `npx eslint .` |
| Format (check) | prettier | `npx prettier --check .` |
| Type-check | tsc | `npx tsc --noEmit` |
| Tests (unit + functional) | vitest | `npx vitest run` |

To auto-repair formatting and safe lint issues locally, run `npm run fix` -- the mutating counterpart -- then review the diff and commit. Never run `fix` in CI or a review hook: the gate must verify, not repair.

The end-to-end (headless-browser) suite is **not** in the fast gate. It runs separately via `npm run e2e` in CI and pre-merge, so the inner TDD loop stays fast. e2e tests are marked `e2e` and live under `tests/e2e/`.

## Coding conventions

These are the conventions `@implementer` and `@code-reviewer` enforce alongside the language-agnostic rules in `AGENTS.md` `<architecture-discipline>`.

### Type annotations

- `strict: true`. Annotate every exported function's params and return type; let inference handle locals. Prefer `unknown` over `any`; never `as any` or `// @ts-ignore`.

### Imports

- ES modules only (`"type": "module"`). `import`/`export`, never `require`. Use `import type { X }` for type-only imports.

### Async / concurrency

- Server/concurrent context: I/O is `async`/`await`. CLI/library with no concurrency: plain sync is fine -- do not add async for its own sake. Never leave a floating promise.

### Error handling

- Throw `Error` subclasses per domain; never throw strings. Fail closed on safety/security.

### Config and secrets

- Read `process.env` at one boundary; validate it (e.g. zod) into a typed config. Secrets in `.env` (gitignored), never hardcoded.

### Logging

- Structured logger (`pino`) or `console` with structured fields; no scattered `console.log` in committed code.

### Test layout and fixtures

- `tests/` mirrors `src/`; unit + functional (`*.test.ts`) run in the fast gate via `vitest run`. `tests/e2e/` holds Playwright specs, excluded from the fast gate, run via `npm run e2e`.
- Inject fakes via params/factories; avoid mocking modules you own.

## Pre-commit hooks

- Not used. The TypeScript profile ships no `.pre-commit-config.yaml`; `npm run qa` (local + CI) is the gate.

## Supply chain

New dependencies pass through the `deps-guard` PreToolUse hook (`.claude/hooks/deps-guard.sh`): it blocks installs of new/named packages until you confirm the package is real and established and will land in the committed lockfile, then re-run with `DEPS_VETTED=1` in front. Install from the lockfile only; no blind `latest`.

## CI

GitHub Actions runs the fast `npm run qa` gate plus a separate end-to-end job (`npm run e2e`). The shipped workflow triggers on **pull requests** and on **pushes to `main`** (see `.github/workflows/qa.yml`).

A red run does not block a merge by itself -- that requires **branch protection** on the repository (Settings -> Branches -> require the `QA` checks to pass). The template cannot configure that for you; enable it once the repo is on GitHub so a red CI actually blocks the merge.

---

*Last updated: 2026-07-12*
