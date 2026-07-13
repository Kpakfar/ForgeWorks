# Language & tooling standards

Language- and tool-specific conventions for this project. Filled in by `/init-project` from your setup answers. Update this file whenever a tooling decision changes.

## Language

- **Language:** Go
- **Version:** 1.25+

## Package management

- **Package manager:** go mod
- **Manifest file:** go.mod
- **Install dependencies:** `go mod download`
- **Add a dependency:** `go get`

Never bypass the package manager. Never install globally.

## Quality-gate toolchain

The bundled command `bash scripts/qa.sh` **verifies only and changes no files**, so it is safe in CI. It chains the following, in order; each must pass for the gate to be green.

| Step | Tool | Command |
|---|---|---|
| Lint (check) | golangci-lint | `golangci-lint run` |
| Format (check) | gofmt | `gofmt -l .` |
| Type-check | go build | `go build ./...` |
| Tests (unit + functional) | go test | `go test ./...` |

To auto-repair formatting and safe lint issues locally, run `bash scripts/fix.sh` -- the mutating counterpart -- then review the diff and commit. Never run `fix` in CI or a review hook: the gate must verify, not repair.

The end-to-end (headless-browser) suite is **not** in the fast gate. It runs separately via `bash scripts/e2e.sh` in CI and pre-merge, so the inner TDD loop stays fast. e2e tests are marked `e2e` and live under `tests/e2e/`.

## Coding conventions

These are the conventions `@implementer` and `@code-reviewer` enforce alongside the language-agnostic rules in `AGENTS.md` `<architecture-discipline>`.

### Type annotations

- Statically typed; the compiler is the type checker (`go build ./...`). Explicit types on exported signatures; `:=` for obvious locals. Keep zero values meaningful.

### Imports

- Group stdlib / third-party / local, blank-line separated. `goimports` (fix.sh) sorts and prunes. Unused imports fail compilation.

### Async / concurrency

- Concurrency is goroutines + channels, only where it earns its keep; CLI/script/library stays sequential. Use `context.Context` on I/O paths; never leak goroutines.

### Error handling

- Return `error` last; check it immediately. Wrap with `fmt.Errorf("...: %w", err)`; inspect with `errors.Is`/`As`. Reserve `panic` for unrecoverable state. Fail closed.

### Config and secrets

- Config from env (`os.Getenv`) or flags; never hardcode keys/URLs/models. Secrets out of source and `go.mod`.

### Logging

- `log/slog` (structured), not `fmt.Println`, for application logs.

### Test layout and fixtures

- `_test.go` files beside the code (`package app`) run in the fast gate via `go test ./...`. `tests/e2e/` is `//go:build e2e`-gated, excluded from the fast gate, run via `scripts/e2e.sh`.
- Table-driven tests + `t.Run` subtests. Inject fakes via interfaces you own; avoid mocking frameworks.

## Pre-commit hooks

- Not used. The Go profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.

## Supply chain

New dependencies pass through the `deps-guard` PreToolUse hook (`.claude/hooks/deps-guard.sh`): it blocks installs of new/named packages until you confirm the package is real and established and will land in the committed lockfile, then re-run with `DEPS_VETTED=1` in front. Install from the lockfile only; no blind `latest`.

## CI

GitHub Actions runs the fast `bash scripts/qa.sh` gate plus a separate end-to-end job (`bash scripts/e2e.sh`). The shipped workflow triggers on **pull requests** and on **pushes to `main`** (see `.github/workflows/qa.yml`).

A red run does not block a merge by itself -- that requires **branch protection** on the repository (Settings -> Branches -> require the `QA` checks to pass). The template cannot configure that for you; enable it once the repo is on GitHub so a red CI actually blocks the merge.

---

*Last updated: 2026-07-12*
