# Language & tooling standards

Language- and tool-specific conventions for this project. Filled in by `/init-project` from your setup answers. Update this file whenever a tooling decision changes.

## Language

- **Language:** Python
- **Version:** 3.12+

## Package management

- **Package manager:** uv
- **Manifest file:** pyproject.toml
- **Install dependencies:** `uv sync`
- **Add a dependency:** `uv add`

Never bypass the package manager. Never install globally.

## Quality-gate toolchain

The bundled command `uv run qa` **verifies only and changes no files**, so it is safe in CI. It chains the following, in order; each must pass for the gate to be green.

| Step | Tool | Command |
|---|---|---|
| Lint (check) | ruff | `uv run ruff check .` |
| Format (check) | ruff format | `uv run ruff format --check .` |
| Type-check | mypy | `uv run mypy src/` |
| Tests (unit + functional) | pytest | `uv run pytest -m 'not e2e'` |

To auto-repair formatting and safe lint issues locally, run `uv run fix` -- the mutating counterpart -- then review the diff and commit. Never run `fix` in CI or a review hook: the gate must verify, not repair.

The end-to-end (headless-browser) suite is **not** in the fast gate. It runs separately via `bash scripts/e2e.sh` in CI and pre-merge, so the inner TDD loop stays fast. e2e tests are marked `e2e` and live under `tests/e2e/`.

## Coding conventions

These are the conventions `@implementer` and `@code-reviewer` enforce alongside the language-agnostic rules in `AGENTS.md` `<architecture-discipline>`.

### Type annotations

- Python 3.12+ syntax: `list[int]` not `List[int]`. `dict[str, X]` not `Dict[str, X]`.
- Every function signature fully typed, including return types.
- `from __future__ import annotations` at the top of every module.

### Imports

- Order: stdlib -> third-party -> local. Sorted by ruff (`I` rule set).
- One module per import line for stdlib and third-party.
- If a name is used ONLY in annotations, ruff's TC rules will move it under `if TYPE_CHECKING:` -- but a name a framework resolves at RUNTIME from the annotation (e.g. FastAPI's `Request`/`Response`/`UploadFile` in route signatures) must stay a real import. Keep those imports at runtime and mark them `# noqa: TC002` if flagged.

### Async / concurrency

- Match the project shape: in a server or any concurrent context, I/O (HTTP, DB, LLM) should be `async`. In a CLI, script, batch job, or library with no concurrency, plain sync is simpler and fine -- do not add async for its own sake.
- When you do go async, use `asyncio.TaskGroup` (Python 3.11+) for concurrent work, and keep the whole I/O path async (no sync calls blocking the loop).

### Error handling

- Specific exception classes per domain. Never bare `Exception`.
- Fail-closed on safety/security: if uncertain, refuse rather than proceed.
- Framework dependency-injection defaults (e.g. FastAPI `Depends(...)`) are called markers, not values: never replace `Depends(get_settings)` with a bare `get_settings()` call at import time -- the first form resolves per-request, the second freezes one instance at import and 500s under test overrides.

### Config and secrets

- `pydantic-settings` for all configuration.
- Never hardcode API keys, URLs, or model names. Pull from env or settings.

### Logging

- `logging` module, not `print`.
- Structured log lines (JSON if going to ingest, key=value otherwise).

### Test layout and fixtures

- `tests/` mirrors `src/` structure. Unit + functional tests run in the fast gate.
- `tests/e2e/` holds end-to-end tests marked `@pytest.mark.e2e`; they are excluded from the fast gate and run via `scripts/e2e.sh` in CI. For a UI use `pytest-playwright` (headless browser); for API-only assert the full request -> response -> persisted-state path.
- Security/red-team tests are marked `@pytest.mark.security` and follow the `docs/SECURITY.md` checklist.
- Use `pytest-asyncio` for async tests. Inject fakes via fixtures/dependency objects; no mocks for code you own.
- `factory-boy` or hand-rolled fixtures in `tests/fixtures/` for data.
- `hypothesis` for property-based tests on pure functions.
- `--import-mode=importlib` is set in addopts: test files may share basenames across folders without `__init__.py` shims.

## Pre-commit hooks

This profile ships `.pre-commit-config.yaml` with `ruff` (`--fix`) and `ruff-format`, plus the generic hooks (trailing-whitespace, yaml/toml/json validation, large-file guard). Install once with `uv run pre-commit install`. (TypeScript, Go, and Rust profiles ship no pre-commit; their `qa` gate + CI are the enforcement.)

## Supply chain

New dependencies pass through the `deps-guard` PreToolUse hook (`.claude/hooks/deps-guard.sh`): it blocks installs of new/named packages until you confirm the package is real and established and will land in the committed lockfile, then re-run with `DEPS_VETTED=1` in front. Install from the lockfile only; no blind `latest`.

## CI

GitHub Actions runs the fast `uv run qa` gate plus a separate end-to-end job (`bash scripts/e2e.sh`). The shipped workflow triggers on **pull requests** and on **pushes to `main`** (see `.github/workflows/qa.yml`).

A red run does not block a merge by itself -- that requires **branch protection** on the repository (Settings -> Branches -> require the `QA` checks to pass). The template cannot configure that for you; enable it once the repo is on GitHub so a red CI actually blocks the merge.

---

*Last updated: 2026-07-12*
