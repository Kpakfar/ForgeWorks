# Language profiles

The YAML blocks below are the human-readable profile reference (commands for
Phase 4.5, CI notes, conventions). The renderer consumes the machine-readable
copy at `templates/profiles/<lang>/profile.json` -- when you change a value
here, change it there too (CI cross-checks the load-bearing scalars).

### Python (fully supported)

```yaml
language_version: "3.12+"
file_extension: "py"
package_manager: "uv"
manifest_file: "pyproject.toml"
install_command: "uv sync"
add_dep_command: "uv add"
qa_command: "uv run qa"
fix_command: "uv run fix"
e2e_command: "bash scripts/e2e.sh"
audit_command: "uv export --frozen --no-emit-project --format requirements-txt -q -o /tmp/audit-requirements.txt && uvx --from 'pip-audit==2.10.1' pip-audit --disable-pip --require-hashes -r /tmp/audit-requirements.txt"
e2e_browser_install: "uv run playwright install --with-deps chromium"
test_runner: "pytest"
test_path_regex: '^tests/'
inline_test_regex: ''
test_command: "uv run pytest -m 'not e2e'"
lint_tool: "ruff"
lint_command: "uv run ruff check ."
format_tool: "ruff format"
format_command: "uv run ruff format --check ."
type_tool: "mypy"
type_command: "uv run mypy src/"
precommit_install_command: "uv run pre-commit install"

ci_setup_steps: |
  - name: Set up uv
    uses: astral-sh/setup-uv@d4b2f3b6ecc6e67c4457f6d3e41ec42d3d0fcb86 # v5
    with:
      enable-cache: true
  - name: Set up Python
    run: uv python install 3.12
  - name: Install deps
    run: uv sync

precommit_hooks: |
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.8
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

library_docs_urls: |
  ### Core stack
  - **uv**: https://docs.astral.sh/uv/
  - **ruff**: https://docs.astral.sh/ruff/
  - **mypy**: https://mypy.readthedocs.io/
  - **pytest**: https://docs.pytest.org/
  - **Pydantic v2**: https://docs.pydantic.dev/latest/
  - **pydantic-settings**: https://docs.pydantic.dev/latest/concepts/pydantic_settings/

  ### AI / RAG (use Context7 first)
  - **OpenAI SDK**: https://github.com/openai/openai-python
  - **Anthropic SDK**: https://github.com/anthropics/anthropic-sdk-python
  - **LangChain**: https://python.langchain.com/docs/introduction/
  - **Chroma**: https://docs.trychroma.com/
  - **pgvector**: https://github.com/pgvector/pgvector

  ### Frontend (if applicable)
  - **Streamlit**: https://docs.streamlit.io/
  - **Gradio**: https://www.gradio.app/docs

notes:
  type_annotations: |
    - Python 3.12+ syntax: `list[int]` not `List[int]`. `dict[str, X]` not `Dict[str, X]`.
    - Every function signature fully typed, including return types.
    - `from __future__ import annotations` at the top of every module.
  imports: |
    - Order: stdlib -> third-party -> local. Sorted by ruff (`I` rule set).
    - One module per import line for stdlib and third-party.
    - If a name is used ONLY in annotations, ruff's TC rules will move it under `if TYPE_CHECKING:` -- but a name a framework resolves at RUNTIME from the annotation (e.g. FastAPI's `Request`/`Response`/`UploadFile` in route signatures) must stay a real import. Keep those imports at runtime and mark them `# noqa: TC002` if flagged.
  async: |
    - Match the project shape: in a server or any concurrent context, I/O (HTTP, DB, LLM) should be `async`. In a CLI, script, batch job, or library with no concurrency, plain sync is simpler and fine -- do not add async for its own sake.
    - When you do go async, use `asyncio.TaskGroup` (Python 3.11+) for concurrent work, and keep the whole I/O path async (no sync calls blocking the loop).
  errors: |
    - Specific exception classes per domain. Never bare `Exception`.
    - Fail-closed on safety/security: if uncertain, refuse rather than proceed.
    - Framework dependency-injection defaults (e.g. FastAPI `Depends(...)`) are called markers, not values: never replace `Depends(get_settings)` with a bare `get_settings()` call at import time -- the first form resolves per-request, the second freezes one instance at import and 500s under test overrides.
  config: |
    - `pydantic-settings` for all configuration.
    - Never hardcode API keys, URLs, or model names. Pull from env or settings.
  logging: |
    - `logging` module, not `print`.
    - Structured log lines (JSON if going to ingest, key=value otherwise).
  test_layout: |
    - `tests/` mirrors `src/` structure. Unit + functional tests run in the fast gate.
    - `tests/e2e/` holds end-to-end tests marked `@pytest.mark.e2e`; they are excluded from the fast gate and run via `scripts/e2e.sh` in CI. For a UI use `pytest-playwright` (headless browser); for API-only assert the full request -> response -> persisted-state path.
    - Security/red-team tests are marked `@pytest.mark.security` and follow the `docs/SECURITY.md` checklist.
    - Use `pytest-asyncio` for async tests. Inject fakes via fixtures/dependency objects; no mocks for code you own.
    - `factory-boy` or hand-rolled fixtures in `tests/fixtures/` for data.
    - `hypothesis` for property-based tests on pure functions.
    - `--import-mode=importlib` is set in addopts: test files may share basenames across folders without `__init__.py` shims.
  precommit_hooks: |
    This profile ships `.pre-commit-config.yaml` with `ruff` (`--fix`) and `ruff-format`, plus the generic hooks (trailing-whitespace, yaml/toml/json validation, large-file guard). Install once with `uv run pre-commit install`. (TypeScript, Go, and Rust profiles ship no pre-commit; their `qa` gate + CI are the enforcement.)
```

### TypeScript (complete)

Files live in `templates/profiles/typescript/`. The gate is expressed as npm scripts in `package.json` (qa is verify-only; fix mutates; e2e is separate). Ships no pre-commit config.

```yaml
language_version: "Node 24 (LTS) / TypeScript 5.7+"
file_extension: "ts"
package_manager: "npm"
manifest_file: "package.json"
install_command: "npm install"
add_dep_command: "npm install"
qa_command: "npm run qa"
fix_command: "npm run fix"
e2e_command: "npm run e2e"
audit_command: "npm audit --audit-level=high"
e2e_browser_install: "npx playwright install --with-deps chromium"
test_runner: "vitest"
test_path_regex: '\.(test|spec)\.[jt]sx?$|^tests/'
inline_test_regex: ''
test_command: "npx vitest run"
lint_tool: "eslint"
lint_command: "npx eslint ."
format_tool: "prettier"
format_command: "npx prettier --check ."
type_tool: "tsc"
type_command: "npx tsc --noEmit"
precommit_install_command: ""   # TypeScript profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Node
    uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
    with:
      node-version: '24'
      cache: 'npm'
  - name: Install deps
    run: npm ci

library_docs_urls: |
  ### Core stack
  - **TypeScript**: https://www.typescriptlang.org/docs/
  - **Vitest**: https://vitest.dev/
  - **ESLint (flat config)**: https://eslint.org/docs/latest/
  - **typescript-eslint**: https://typescript-eslint.io/
  - **Prettier**: https://prettier.io/docs/
  - **Playwright**: https://playwright.dev/docs/intro

notes:
  type_annotations: |
    - `strict: true`. Annotate every exported function's params and return type; let inference handle locals. Prefer `unknown` over `any`; never `as any` or `// @ts-ignore`.
  imports: |
    - ES modules only (`"type": "module"`). `import`/`export`, never `require`. Use `import type { X }` for type-only imports.
  async: |
    - Server/concurrent context: I/O is `async`/`await`. CLI/library with no concurrency: plain sync is fine -- do not add async for its own sake. Never leave a floating promise.
  errors: |
    - Throw `Error` subclasses per domain; never throw strings. Fail closed on safety/security.
  config: |
    - Read `process.env` at one boundary; validate it (e.g. zod) into a typed config. Secrets in `.env` (gitignored), never hardcoded.
  logging: |
    - Structured logger (`pino`) or `console` with structured fields; no scattered `console.log` in committed code.
  test_layout: |
    - `tests/` mirrors `src/`; unit + functional (`*.test.ts`) run in the fast gate via `vitest run`. `tests/e2e/` holds Playwright specs, excluded from the fast gate, run via `npm run e2e`.
    - Inject fakes via params/factories; avoid mocking modules you own.
  precommit_hooks: |
    - Not used. The TypeScript profile ships no `.pre-commit-config.yaml`; `npm run qa` (local + CI) is the gate.
```

### Go (complete)

Files live in `templates/profiles/go/`. The gate is `scripts/qa.sh` (verify-only: gofmt-check, vet, golangci-lint, test); fix mutates; e2e is build-tag gated (`//go:build e2e`). Ships no pre-commit config.

```yaml
language_version: "1.25+"
file_extension: "go"
package_manager: "go mod"
manifest_file: "go.mod"
install_command: "go mod download"
add_dep_command: "go get"
qa_command: "bash scripts/qa.sh"
fix_command: "bash scripts/fix.sh"
e2e_command: "bash scripts/e2e.sh"
audit_command: "go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./..."
e2e_browser_install: ""   # Go e2e is API/CLI-level by default (no browser)
test_runner: "go test"
test_path_regex: '_test\.go$'
inline_test_regex: ''
test_command: "go test -race ./..."
lint_tool: "golangci-lint"
lint_command: "golangci-lint run"
format_tool: "gofmt"
format_command: "gofmt -l ."   # CHECK form (lists unformatted files); fix.sh does -w
type_tool: "go build"
type_command: "go build ./..."
precommit_install_command: ""   # Go profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Go
    uses: actions/setup-go@40f1582b2485089dde7abd97c1529aa768e1baff # v5
    with:
      go-version: "1.25"
      cache: true
  - name: Download modules
    run: go mod download
  - name: Install golangci-lint (pinned + checksum-verified)
    run: |
      curl -sSfL -o /tmp/golangci-install.sh https://raw.githubusercontent.com/golangci/golangci-lint/v2.12.2/install.sh
      echo "d32d3534af96cfd59546a084d22b213e8a47541cada5013aa8a84c4fa2589905  /tmp/golangci-install.sh" | sha256sum -c -
      sh /tmp/golangci-install.sh -b "$(go env GOPATH)/bin" v2.12.2
      echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"

library_docs_urls: |
  ### Core stack
  - **Effective Go (idioms)**: https://go.dev/doc/effective_go
  - **Managing dependencies**: https://go.dev/doc/modules/managing-dependencies
  - **testing package**: https://pkg.go.dev/testing
  - **golangci-lint**: https://golangci-lint.run/

notes:
  type_annotations: |
    - Statically typed; the compiler is the type checker (`go build ./...`). Explicit types on exported signatures; `:=` for obvious locals. Keep zero values meaningful.
  imports: |
    - Group stdlib / third-party / local, blank-line separated. `goimports` (fix.sh) sorts and prunes. Unused imports fail compilation.
  async: |
    - Concurrency is goroutines + channels, only where it earns its keep; CLI/script/library stays sequential. Use `context.Context` on I/O paths; never leak goroutines.
  errors: |
    - Return `error` last; check it immediately. Wrap with `fmt.Errorf("...: %w", err)`; inspect with `errors.Is`/`As`. Reserve `panic` for unrecoverable state. Fail closed.
  config: |
    - Config from env (`os.Getenv`) or flags; never hardcode keys/URLs/models. Secrets out of source and `go.mod`.
  logging: |
    - `log/slog` (structured), not `fmt.Println`, for application logs.
  test_layout: |
    - `_test.go` files beside the code (`package app`) run in the fast gate via `go test ./...`. `tests/e2e/` is `//go:build e2e`-gated, excluded from the fast gate, run via `scripts/e2e.sh`.
    - Table-driven tests + `t.Run` subtests. Inject fakes via interfaces you own; avoid mocking frameworks.
  precommit_hooks: |
    - Not used. The Go profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.
```

### Rust (complete)

Files live in `templates/profiles/rust/`. The gate is `scripts/qa.sh` (verify-only: line cap, fmt-check, clippy with warnings-as-errors, check, test); fix mutates; e2e tests are `#[ignore]`-tagged in `tests/e2e.rs` and run via `scripts/e2e.sh`. The toolchain (compiler + clippy + rustfmt) is pinned by `rust-toolchain.toml`, which rustup honors everywhere (local, dev container, CI). The manifest ships as a plain `Cargo.toml` (no `.example` suffix needed: cargo never scans nested directories, so the template copy is inert -- unlike Python's `pyproject.toml`). Ships no pre-commit config.

```yaml
language_version: "1.96 (edition 2024; pinned by rust-toolchain.toml)"
file_extension: "rs"
package_manager: "cargo"
manifest_file: "Cargo.toml"
install_command: "cargo fetch"
add_dep_command: "cargo add"
qa_command: "bash scripts/qa.sh"
fix_command: "bash scripts/fix.sh"
e2e_command: "bash scripts/e2e.sh"
audit_command: "cargo install cargo-audit --locked --version 0.22.2 && cargo audit"
e2e_browser_install: ""   # Rust e2e is API/CLI-level by default (no browser)
test_runner: "cargo test"
test_path_regex: '^tests/'
inline_test_regex: '#\[test\]|#\[cfg\(test\)\]|\bassert(_eq|_ne)?!'
test_command: "cargo test"
lint_tool: "clippy"
lint_command: "cargo clippy --all-targets -- -D warnings"
format_tool: "rustfmt"
format_command: "cargo fmt --check"   # CHECK form; fix.sh runs `cargo fmt` (write)
type_tool: "cargo check"
type_command: "cargo check"
precommit_install_command: ""   # Rust profile ships no pre-commit; qa + CI are the gate

ci_setup_steps: |
  - name: Set up Rust
    # Installs the toolchain pinned in rust-toolchain.toml (channel + the
    # clippy/rustfmt components) and enables cargo caching. rustflags is
    # cleared so the scripts alone define strictness (qa runs clippy with
    # -D warnings); the action would otherwise export RUSTFLAGS="-D warnings"
    # and make plain builds stricter in CI than locally.
    uses: actions-rust-lang/setup-rust-toolchain@166cdcfd11aee3cb47222f9ddb555ce30ddb9659 # v1
    with:
      rustflags: ""
  - name: Fetch dependencies
    run: cargo fetch

library_docs_urls: |
  ### Core stack
  - **The Rust Book**: https://doc.rust-lang.org/book/
  - **Standard library**: https://doc.rust-lang.org/std/
  - **The Cargo Book**: https://doc.rust-lang.org/cargo/
  - **Clippy lint list**: https://rust-lang.github.io/rust-clippy/master/
  - **rustfmt**: https://github.com/rust-lang/rustfmt

notes:
  type_annotations: |
    - Statically typed; the compiler is the type checker (`cargo check`). Explicit types on public signatures; let inference handle locals. Prefer borrowed views (`&str`, `&[T]`) for parameters and owned types for returns.
  imports: |
    - `use` statements at the top, grouped stdlib / third-party / crate-local, blank-line separated (rustfmt keeps each group sorted). No wildcard imports outside preludes and test modules.
  async: |
    - Add async (tokio) only when the project is genuinely concurrent (server, many parallel I/O calls); a CLI, batch job, or library stays synchronous -- do not add an async runtime for its own sake. When async, keep the whole I/O path async and never block the executor (no `std::thread::sleep` or sync file I/O inside it).
  errors: |
    - Return `Result<T, E>` with a domain error enum (`thiserror` in libraries; `anyhow` acceptable at the application boundary). No `unwrap()`/`expect()` outside tests and provably-infallible spots; `?` for propagation; `panic!` only for unrecoverable invariants. Fail closed on safety/security.
  config: |
    - Read env at one boundary into a typed config struct; never hardcode keys/URLs/models. Secrets in `.env` (gitignored), never in source or Cargo.toml.
  logging: |
    - `tracing` (structured, with spans) for application logs -- not `println!`.
  test_layout: |
    - Unit tests live beside the code in `#[cfg(test)] mod tests` blocks; integration tests in `tests/`; both run in the fast gate via `cargo test`. `tests/e2e.rs` is `#[ignore]`-tagged, excluded from the fast gate, run via `scripts/e2e.sh` (`cargo test --test e2e -- --ignored`).
    - Table-style cases via loops over input/expected pairs; inject fakes via traits you own; avoid mocking frameworks.
  precommit_hooks: |
    - Not used. The Rust profile ships no `.pre-commit-config.yaml`; `bash scripts/qa.sh` (local + CI) is the gate.
```

### Experimental languages (Other)

"Other" has **no profile** -- there is no profile folder to copy, so a generated project would be core-only with no working toolchain. Do not imply otherwise. Get explicit consent first:

> "Heads up: that language isn't a built profile yet. I can lay down the universal core (AGENTS.md, docs, security files, CI shape), but you'd have to build the toolchain yourself -- there's no validated manifest, lint/format/type setup, qa/fix scripts, or green scaffold -- so the first quality-gate run won't pass until you complete it. Proceed on that basis, switch to Python/TypeScript/Go/Rust, or have me add a profile for it properly first?"

If they proceed: `render.py` cannot run without a `profile.json`, so this is the ONE path where generation is manual -- copy `templates/core/` only, substitute the discovery placeholders from the answers file by hand, leave clearly-marked TODOs for the toolchain placeholders in `docs/language-standards.md` and `.github/workflows/qa.yml`, do NOT generate a manifest or scripts, and tell them the gate is not green until they finish the toolchain. The better path is to add a real profile under `templates/profiles/<lang>/` (see the repo `AGENTS.md` `<adding-a-language-profile>`) so the experience matches the complete profiles.

---

