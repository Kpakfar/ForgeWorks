# ForgeWorks: Deep Review and Roadmap

**Scope:** A repository-wide self-review of the bootstrapper, generated development harness, documentation, quality gates, security controls, stack support, and coding-agent portability. Kept in the repo as a record of the build → critique → fix loop.

> **Status (addressed in v1.0.0).** Most of the P0/P1 findings below have since shipped: complete TypeScript and Go profiles with no cross-language leakage (the `core/` + `profiles/` split), the deps-guard flag-bypass fix, the verify-only `qa` split from `fix`, a green-on-first-run scaffold, discovery answers wired into the generated docs, leaner per-answer dependencies, and devcontainer hardening. The larger architectural items (a deterministic scaffold engine, a golden-fixture self-test CI, and cross-agent adapters) remain intentional future roadmap. The original findings are preserved below unchanged.

## Purpose

The intended product is a reusable project template that can:

1. Start a project from scratch.
2. Start from an existing product vision or specification.
3. Work with different agentic coding tools.
4. Install a standard development harness that helps humans and agents produce high-quality code and products.

This review evaluates the repository against those goals. It is a review and roadmap, not an implementation record.

## Executive assessment

The repository has a strong philosophy and several valuable workflow primitives. Its separation of product vision, iteration requirements, current-task memory, backlog slices, living documentation, and specialist review roles is thoughtful. The emphasis on deterministic quality enforcement, security review, and learning across projects is also directionally excellent.

However, the repository is not yet a dependable general-purpose template harness. It is currently closest to a Claude Code and Python prototype. Many guarantees are expressed as instructions to an agent rather than implemented as deterministic behavior. The most important next step is therefore not adding more prompts, languages, or agents; it is making generation reproducible and testable.

### Readiness by intended use

| Intended use | Current readiness | Main limitation |
|---|---|---|
| Start from scratch | Partial | Rich interview, but important answers are not reliably written into the generated documents |
| Start from a product vision | Not explicitly supported | No import or normalization path for an existing vision or specification |
| Add the harness to an existing repository | Not safely supported | Generation is primarily designed for an empty directory and has no deterministic merge plan |
| Claude Code with Python | Closest to usable | Fresh scaffold, quality gate, dependency selection, and security controls still have blockers |
| TypeScript, Rust, Go, or other languages | Not ready | Profiles are TODOs and the shared base contains Python-specific implementation |
| Codex or another coding agent | Partial | `AGENTS.md` is portable, but orchestration, hooks, MCP setup, models, and commands are Claude-specific |

## What is already strong

### Information architecture

- `AGENTS.md` is treated as the project constitution.
- Product vision and current iteration requirements are separate documents.
- `docs/current-task/task.md` provides shared task context.
- Backlog entries are framed as vertical, demonstrable slices.
- Gotchas, security knowledge, project structure, and proposals are living documents.

### Development workflow

- Red, Green, Refactor, and Review are easy to understand.
- Test specification, implementation, code review, security review, and technical-debt review have distinct responsibilities.
- Trivial-task and exploratory-spike escape hatches prevent total process rigidity.
- The recent design discipline correctly asks for inspectable visual artifacts for significant interface decisions.

### Quality and security intent

- The repository recognizes that critical guarantees should live in hooks and CI rather than prompts alone.
- Access control, secrets, supply-chain risk, prompt injection, and blast radius are treated as first-class concerns.
- Recurring security and technical-debt reviews are valuable because those risks accumulate between feature slices.

## Prioritized findings

### P0 — Critical product gaps

#### 1. Important discovery answers are discarded

The initialization interview asks for the core user journey, success measure, concrete example, and riskiest assumption. Those answers do not have complete placeholder mappings or explicit emission rules. The generated `requirements.md` and `PRODUCT_VISION.md` retain TODO sections, and the temporary answer document is deleted after generation.

**Impact:** The strongest part of the interview does not become durable project context. A project can complete an extensive planning conversation and still receive generic documents.

**Required direction:** Normalize every answer into a structured project specification and render all durable product information from that specification.

#### 2. Generation is probabilistic rather than reproducible

`init-project/SKILL.md` currently acts as interview, renderer, conditional engine, migration process, dependency installer, and verification plan. It asks an agent to copy files, replace placeholders, synthesize language artifacts, remove conditional sections, rename files, mutate manifests, and verify the result.

**Impact:** Identical answers can produce different repositories. Failures are difficult to reproduce, and template behavior cannot be confidently regression-tested.

**Required direction:** Create a deterministic scaffold module with a small interface: structured project specification in, generated repository out. Keep the skill as a conversational adapter to that module.

### P1 — Reliability and enforcement gaps

#### 3. The base template is not stack-agnostic

The shared base contains Python-specific QA scripts, a Python devcontainer, a Python-oriented ignore file, and a Python manifest example. TypeScript, Rust, Go, and Other are explicitly incomplete.

**Impact:** Unsupported languages can receive incorrect files or depend on agent improvisation. The public stack-agnostic claim is stronger than the implementation.

**Required direction:** Separate universal files from project-shape and language/toolchain profiles. Unsupported profiles should fail clearly rather than generate a partially valid harness.

#### 4. A fresh Python scaffold is not guaranteed to be green

The generated structure does not include minimal `src/` and `tests/` content, while the QA script runs `mypy src/` and pytest. `README.md` and `.env.example` are referenced in `structure.txt` but are not part of the base template. Phase 5 verifies selected paths but does not run the complete QA gate.

**Impact:** The first advertised verification command can fail before any feature work begins.

**Required direction:** Generate a minimal working source module, smoke test, README, environment example, valid manifest, and lockfile. Execute QA as part of bootstrap verification.

#### 5. The template repository has no automated harness of its own

There is no root CI workflow, renderer test suite, golden fixture matrix, placeholder check, hook regression suite, or generated-project smoke test. The repository documentation states that template changes cannot be unit-tested in the usual sense.

**Impact:** Changes to the generator and templates can silently break future projects.

**Required direction:** Treat the generated repository as the test output. Test rendering, conditionals, file syntax, permissions, first-run QA, and representative profile combinations in root CI.

#### 6. The dependency guard is bypassable

Behavioral checks showed that ordinary commands such as these are not blocked:

```text
npm install --save lodash
pnpm add -D vitest
uv add --dev pytest
pip install --upgrade requests
```

Any command containing the text `DEPS_VETTED` also passes, even if it does not represent completed verification. The hook only matches Bash tool calls and does not intercept direct manifest edits despite documentation claiming that it does.

**Impact:** The control is described as deterministic security enforcement but can be bypassed accidentally or deliberately.

**Required direction:** Parse structured tool input, recognize flags and command forms correctly, inspect manifest and lockfile changes, and define verifiable approval state rather than trusting a marker string.

#### 7. The QA command modifies code instead of only verifying it

The QA script runs Ruff with `--fix` and runs the formatter in write mode. The same command runs in CI.

**Impact:** CI can repair files in its disposable checkout and pass even though the repairs were never committed. A review hook can also introduce changes after the code was reviewed.

**Required direction:** Split the tooling into two commands:

- `qa`: non-mutating lint, format check, type check, and tests.
- `fix`: formatting and safe automatic repair for local use.

#### 8. Supply-chain policy contradicts bootstrap behavior

The bootstrap and generated configuration rely on mutable or unverified sources, including:

- Remote shell execution from the `main` branch.
- `npx` packages resolved through `latest`.
- Template and skill downloads from mutable branches.
- Context7 installed through `@latest`.
- GitHub Actions referenced by tags instead of immutable commit SHAs.
- The uv installer downloaded and executed without integrity verification.

**Impact:** The bootstrap path violates the supply-chain standard that generated projects are told to enforce.

**Required direction:** Publish immutable template releases, pin tools and actions, verify downloaded artifacts, and record resolved versions in the generated repository.

#### 9. The devcontainer weakens its isolation story

The devcontainer mounts the entire host `~/.claude` directory, including files that may contain credentials. It also enables Docker-in-Docker by default. Its post-create command swallows failures from dependency synchronization and invokes `pre-commit` outside the managed Python environment.

**Impact:** The container can expose host credentials and hide a broken environment while being presented as a safer execution environment.

**Required direction:** Mount only explicitly required, read-only configuration; avoid secret-bearing directories; make elevated features opt-in; and fail visibly when environment setup fails.

#### 10. Cross-agent compatibility is mostly nominal

`AGENTS.md` provides a useful portable constitution, but most of the operational harness uses Claude-specific conventions:

- `.claude/agents/`
- Claude hook schemas and lifecycle events
- Claude project MCP configuration
- Claude model names
- Claude subagent invocation examples
- Slash commands and scheduling behavior

**Impact:** Codex and other coding agents do not receive the same workflow or deterministic controls.

**Required direction:** Define a universal core and provide separate coding-agent adapters. CI should remain the shared final enforcement layer.

### P2 — Quality and consistency gaps

#### 11. Python dependencies ignore interview choices

The manifest example includes FastAPI, PostgreSQL tooling, pgvector, OpenAI, Anthropic, and other packages regardless of selected framework, database, vector store, or model provider.

**Impact:** Generated projects receive unnecessary dependencies, slower setup, larger attack surface, and misleading architecture.

**Required direction:** Derive manifest dependencies only from selected capabilities and profiles.

#### 12. Public documentation has drifted

The usage guide still describes approximately six questions, per-stack template directories, and copying a stack template. The current implementation uses fifteen questions and a shared base with language profiles. The bootstrap output also refers to three generated subagents although five are now present.

**Impact:** Contributors and users cannot tell which workflow is authoritative.

**Required direction:** Generate or test documentation claims against the same profile metadata used by the renderer.

#### 13. Some universal rules are overly rigid

The generated constitution assumes a backend/frontend split, strongly encourages a complete test pyramid for each slice, sets universal file-length caps, and requires all Python I/O to be asynchronous.

**Impact:** Rules that improve one web application can reduce quality in a CLI, library, data pipeline, notebook, or small internal tool. They can encourage fragmentation and unnecessary implementation complexity.

**Required direction:** Make standards risk-based and project-shape-aware. Defaults should guide judgment rather than replace it.

#### 14. CI claims are stronger than CI configuration

The documentation says CI runs on every push and that a red run blocks merging. The workflow only runs push builds for `main`, and merge blocking depends on repository branch-protection settings that this template does not configure.

**Impact:** Users may believe guarantees exist when they require additional repository configuration.

**Required direction:** Describe exact behavior, provide branch-protection setup guidance or automation, and test workflow triggers.

#### 15. End-to-end setup is incomplete

The Python profile includes Playwright dependencies, but browser installation in CI is commented out. The e2e script treats absence of tests as success.

**Impact:** The project advertises a working headless-browser gate that may fail when the first real browser test is introduced, while an empty suite appears healthy.

**Required direction:** Install required browsers conditionally when UI e2e is selected and distinguish “not configured,” “no tests,” and “tests passed.”

## Target architecture

### 1. Structured project specification

All intake paths should produce one versioned specification, for example:

```text
Project identity
Product vision
Primary user and core journey
Success measure and riskiest assumption
Explicit non-goals
Project shape
Language and toolchain profile
Selected capabilities
Security profile
Coding-agent adapters
Development-environment choices
```

This specification becomes the single source of truth for generation and regeneration.

### 2. Deterministic scaffold module

The scaffold module should have a narrow interface and hide the complete generation implementation behind it. Its responsibilities should include:

- Validate the project specification.
- Resolve compatible profiles and versions.
- Render universal files.
- Render selected project-shape, language, capability, and coding-agent adapters.
- Escape values correctly for Markdown, TOML, YAML, JSON, and shell contexts.
- Produce a dry-run manifest of created, replaced, skipped, and conflicting paths.
- Refuse unsafe overwrites unless explicitly authorized.
- Verify the resulting repository.

This produces leverage for all intake modes and locality for generation defects.

### 3. Intake adapters

Provide three explicit adapters at the project-intake seam:

1. **Greenfield interview adapter:** conducts discovery and fills the specification.
2. **Product-vision adapter:** reads an existing document, extracts known decisions, and asks only for missing information.
3. **Existing-repository adapter:** inspects the repository, proposes a merge plan, and installs only missing harness pieces.

### 4. Profile model

Use separate profile categories:

- **Project shape:** web application, CLI, library, data pipeline, notebook/research project.
- **Language/toolchain:** Python, TypeScript, Rust, Go.
- **Capability:** frontend, persistence, AI, RAG, browser e2e, container, memory.
- **Coding-agent adapter:** Claude Code, Codex, generic `AGENTS.md`, and later adapters when genuinely supported.

Do not claim a profile is supported until it passes the complete generated-project test matrix.

## Recommended implementation sequence

### Phase 1: Make the current Python path trustworthy

1. Create the deterministic scaffold module.
2. Define and validate the structured project specification.
3. Preserve all interview answers in generated documents.
4. Make the smallest Python scaffold pass QA immediately.
5. Split `qa` from `fix`.
6. Add root CI and generated-project smoke tests.
7. Add placeholder, syntax, file-permission, and hook regression tests.

**Exit criterion:** A fixed Python specification always produces the same repository, and that repository passes QA in CI.

### Phase 2: Correct security and bootstrap trust

1. Publish immutable template versions.
2. Pin external tools, skills, actions, container images, and MCP packages.
3. Replace marker-based dependency approval with a verifiable process.
4. Remove broad host-configuration mounts from the devcontainer.
5. Ensure bootstrap and post-create failures are visible and recoverable.

**Exit criterion:** Security claims accurately describe mechanically tested controls.

### Phase 3: Support the intended starting modes

1. Add product-vision import.
2. Add existing-repository inspection and merge planning.
3. Add dry-run, conflict reporting, resume, and idempotence tests.
4. Generate the first backlog slices from the core journey and riskiest assumption.

**Exit criterion:** Scratch, product-vision, and existing-repository inputs converge on the same project specification and scaffold module.

### Phase 4: Create real coding-agent portability

1. Extract the universal agent constitution.
2. Keep shared quality guarantees in scripts and CI.
3. Add a Claude Code adapter for agents, hooks, MCP, and scheduling.
4. Add a Codex adapter with equivalent supported capabilities.
5. Add a generic mode that makes no unsupported orchestration claims.
6. Publish an explicit capability matrix for every adapter.

**Exit criterion:** Each supported coding agent receives tested setup, while unsupported features are clearly identified.

### Phase 5: Expand project-shape and language support

1. Stabilize project-shape profiles.
2. Implement TypeScript completely and test it before adding more languages.
3. Add Rust and Go only when each has a manifest, lockfile strategy, QA, CI, dev environment, and smoke-test fixture.
4. Replace universal architecture rules with profile-aware defaults.

**Exit criterion:** Every advertised profile passes the same readiness contract as Python.

## Required test matrix

At minimum, root CI should generate and verify:

| Case | Required checks |
|---|---|
| Python, no AI, no UI, no container | Deterministic output, syntax, QA passes |
| Python, AI enabled | AI rules and security sections present; selected dependencies only |
| Python UI with browser e2e | Browser installed; smoke e2e runs |
| Devcontainer enabled | Container builds; setup failures are not swallowed |
| Product vision supplied | Existing vision retained; missing information requested or marked |
| Existing repository | Dry-run reports conflicts; no unauthorized overwrite |
| Claude adapter | Hooks and agent definitions validate |
| Codex adapter | Supported instructions and tools validate |
| Generic adapter | No Claude-only claims or files unless requested |
| Windows-compatible mode | Pointer file replaces symlink and verification accepts it |

Every fixture should also verify:

- No unresolved generation placeholders.
- Valid JSON, YAML, TOML, and shell syntax.
- Required scripts are executable.
- Generated documentation matches selected capabilities.
- The dependency manifest contains only selected packages.
- `qa` makes no file changes.
- `fix` is allowed to make expected changes.
- A clean generated repository remains clean after QA.

## Documentation contract

The public documentation should be derived from or tested against the same metadata as the scaffold module. It should state:

- Supported project shapes.
- Supported languages and maturity level.
- Supported coding-agent adapters and capability parity.
- Exact bootstrap inputs and outputs.
- Which controls are local hooks, which are CI checks, and which remain advisory.
- How template versions are pinned and upgraded.
- How to import a product vision.
- How to install the harness into an existing repository.

Generated projects should include a project-specific README explaining the chosen stack, commands, development flow, and agent support.

## Definition of production-ready

The template can be considered production-ready when all of the following are true:

- Identical specifications generate identical repositories.
- Every advertised profile passes root CI and first-run QA.
- Product-vision import preserves existing intent and asks only for missing decisions.
- Existing repositories receive a dry-run and conflict plan before mutation.
- Generated manifests contain only selected dependencies.
- QA is non-mutating and CI detects uncommitted formatting or lint changes.
- Security controls withstand regression tests and match their documentation.
- External bootstrap dependencies are pinned and verifiable.
- Claude, Codex, and generic modes have an honest, tested capability matrix.
- Generated documentation contains the core journey, success measure, risk, non-goals, acceptance criteria, and security profile.
- The template repository tests itself through representative generated projects.
- Template releases are immutable and generated projects record their source version.

## Final recommendation

Do not expand language or coding-agent support yet. First create the deterministic scaffold module, structured project specification, green Python fixture, and root test matrix. These changes establish the depth, leverage, and locality needed for every later profile and adapter.

Once that foundation is reliable, the existing workflow ideas can become a genuinely high-quality, reusable project harness rather than a strong set of instructions whose outcome depends on the agent executing them.
