# ForgeWorks portfolio-readiness re-audit

**Re-audit date:** 2026-06-30  
**Current main:** `113e368`  
**Published release:** `v1.1.0` at `75e8dc8`  
**Purpose:** verify the remediation after the v1.0.0 audit; this is a fresh assessment, not the remediation commit's self-report.

## Verdict

ForgeWorks improved materially. The profile toolchains now have real CI evidence, the known TypeScript vulnerabilities are gone, Go is current and lint-enforced, upgrade provenance is preserved, and the public limitations are much more honest.

**Portfolio decision:** publishable as a transparent engineering beta after the short release-cleanup list below. It is **not yet a production-ready deterministic bootstrapper**. The largest architectural limitation—the agent itself is still the renderer—is now disclosed rather than hidden.

| Area | v1.0.0 | Current | Assessment |
|---|---:|---:|---|
| Product and positioning | 8/10 | 8/10 | Still a strong, differentiated idea. |
| First-use UX | 5/10 | 6/10 | Duplicate skill-install step removed; full journey remains agent-dependent. |
| Generator reliability | 3/10 | 5/10 | Profile CI added, but it does not render or test a complete generated project. |
| Language profiles | 4/10 | 8/10 | Python/TS/Go gates pass in current main CI; TS audit is clean. |
| Upgrade safety | 3/10 | 5/10 | Stamp loss fixed; Go/TS reconciliation remains stale/incomplete. |
| Security posture | 4/10 | 6/10 | Claims are more honest and alerts are enabled; reporting and guard coverage need work. |
| README and docs | 6/10 | 7/10 | Better caveats and roadmap; several current facts already drifted. |
| Open-source / portfolio polish | 4/10 | 6/10 | CI, CONTRIBUTING, SECURITY, Dependabot added; release/branch/community polish remains. |

## What is now verified good

- Current main CI run [28439640926](https://github.com/Kpakfar/ForgeWorks/actions/runs/28439640926) passed all four jobs: sources, Python, TypeScript, and Go.
- Local re-test: Python `uv sync` + `uv run qa` passed; Python `pre-commit run --all-files` passed with the JSONC exclusion.
- Local re-test: TypeScript install + QA passed and `npm audit --audit-level=high` reported **0 vulnerabilities**.
- Go moved from unsupported 1.22 to 1.25; golangci-lint v2 is required rather than silently skipped; the live Go CI job passed.
- `PROJECT_SLUG`, explicit `pyproject.toml.example -> pyproject.toml`, and structured-file escaping instructions were added.
- Installing the upgrade kit now preserves the old stamp. Reproduced with `v0.9.0`: it remained `v0.9.0` until an upgrade runs.
- `deps-guard` now parses `.tool_input.command`, blocks the earlier text-injection trick, and covers pipx/cargo/go paths.
- Root `SECURITY.md`, `CONTRIBUTING.md`, Dependabot config, root CI, and a concise roadmap now exist. GitHub community health rose from 42% to 71%.
- Dependabot security updates, secret scanning, and push protection are enabled.
- The stale 385-line pre-v1 review was removed; release wording now says “versioned”, not “immutable/reproducible”.

## Status of the original blockers

| Original finding | Status | Evidence |
|---|---|---|
| P0-1 deterministic generation / root tests | **Partial** | Root CI copies profiles only; no complete core+profile render, conditional matrix, or golden output. |
| P0-2 Python manifest rename | **Resolved** | Explicit Phase 4 rename and CI rename. |
| P0-3 identifiers and escaping | **Partial** | Slug and instructions added; escaping remains LLM-executed and hostile values are not tested. |
| P0-4 obsolete Go / skipped lint | **Resolved** | Go 1.25 + required golangci-lint v2; CI green. |
| P0-5 TypeScript vulnerabilities | **Resolved** | Vitest 3.2.6; local and CI audit pass. |
| P0-6 upgrade stamp / stale base path | **Partial** | Stamp and `templates/base` fixed; Go/TS upgrade rules remain stale. |
| P0-7 dependency guard overclaim/bypasses | **Partial** | Public claim downgraded; several execution paths still bypass it. |
| P0-8 immutable/reproducible claim | **Resolved as honesty** | Limitations disclosed; hardening remains roadmap. |
| P1-1 contradictory public instructions | **Mostly resolved** | Current Go status, bootstrap package-manager names, and pre-commit wording still drift. |
| P1-2 neutral-core leakage | **Partial** | RADAR/Pydantic/path fixed in some files; non-AI leakage remains. |
| P1-3 Python pre-commit vs JSONC | **Resolved** | Re-tested successfully. |
| P1-4 container / lockfile paths | **Partial** | TS container no longer fails immediately, but first install is still unlocked. |
| P1-5 repo does not dogfood standards | **Partial** | CI/community/security files added; main is still unprotected. |
| P1-6 stale roadmap / line caps | **Partial** | Roadmap replaced; `init-project/SKILL.md` is now 744 lines against the 200-line cap. |
| P1-7 generated docs remain unfinished | **Open** | Product vision, acceptance criteria, security profile, constraints, and AI sections retain broad TODOs. |
| P1-8 cross-agent overclaim | **Resolved as honesty** | README and roadmap now distinguish portable prose from Claude orchestration. |

## Release blockers to fix next

### R1 — `v1.1.0` is not the green commit

The `v1.1.0` tag points to `75e8dc8`; its CI run [28439529652](https://github.com/Kpakfar/ForgeWorks/actions/runs/28439529652) is red because the source placeholder check was wrong. All three profile jobs passed, but the release commit's overall gate did not. Main fixed CI in `113e368` and is green. The published installer remains pinned to the red-tagged commit.

**Action:** do not move the tag. Finish the corrections in this report, ensure exact-commit CI is green, then cut `v1.1.1` (or the semver level required by generated-structure changes).

### R2 — Security reporting points to a disabled feature

`SECURITY.md:10-14` tells users to open a private security advisory, but GitHub reports private vulnerability reporting as `enabled: false`. Its fallback is a public issue, which is unsafe for a real vulnerability.

**Action:** enable private vulnerability reporting or provide a monitored security email. Remove the public-issue fallback for undisclosed vulnerabilities.

### R3 — Upgrade behavior is still Python-centric

`upgrade-project/SKILL.md:74` calls every `scripts/e2e.sh` Python-specific and instructs non-Python projects to receive a passing TODO stub. This discards the real Go e2e runner. Lines 80-85 implement tooling deltas only for Python and tell TypeScript/Go users to accept TODOs, despite both being advertised complete.

**Action:** reconcile the selected profile verbatim where safe, add explicit v1.0→v1.1 deltas for all three languages, and test upgrade fixtures for Python, TypeScript, and Go—including a second idempotence run.

### R4 — Root CI overstates what it proves

`.github/workflows/ci.yml:3-5` says each profile “generates a project”. It only copies the profile directory and substitutes the manifest/module file. It never renders `core/`, applies AI/devcontainer/explanation/memory conditionals, validates generated YAML, checks executable bits/symlinks, tests hostile display values, or exercises init/upgrade. The comment at lines 37-40 incorrectly says leftover placeholders would be caught by profile installs; placeholders in core are never copied.

**Action:** rename the current jobs “profile smoke tests” and keep them. Add a deterministic renderer or, until then, scripted representative full-tree fixtures with positive and negative assertions. Do not use “complete generation evidence” for profile-only tests.

## High-priority follow-ups

### R5 — Root `CLAUDE.md` stopped being a symlink

`CLAUDE.md` and `AGENTS.md` are now two regular files with identical blobs (`100644`), while README, CONTRIBUTING, and the constitution say `CLAUDE.md` symlinks to `AGENTS.md`. Future edits can drift.

**Action:** restore the symlink (`120000`) and add a source check for it.

### R6 — Documentation already trails the successful CI

README lines 57/65, `docs/ROADMAP.md:13-16,36-37`, and `docs/how-to-use.md:69` say Go is pending its first CI run. It passed twice, including on the tag commit. CONTRIBUTING line 26 still says the template cannot be unit-tested, immediately after root CI was added. Bootstrap output still says `pnpm` and implies every profile has pre-commit, while TypeScript uses npm and only Python ships pre-commit.

**Action:** update claims from the same profile metadata/CI evidence; avoid hand-maintained maturity text in four files.

### R7 — Guard coverage improved, but the remediation claim is too strong

Current retest still allows `npm --prefix . install`, `npx`, `npm exec`, `pnpm dlx`, `yarn dlx`, `bunx`, and `uvx`. `DEPS_VETTED=0` is accepted although docs require `=1`. The public “best-effort” wording is now fair, but the v1.1.0 commit says all audited bypasses block, which is false (`npx` and `npm --prefix` were in the audit).

**Action:** match only `DEPS_VETTED=1`; cover remote-execution forms or explicitly list them as limitations; keep regression cases in root CI.

### R8 — Dependabot's Go configuration is structurally incompatible

The live Go dependency-graph/Dependabot runs fail because the template `go.mod` contains `{{PROJECT_SLUG}}`, which is not a valid module path until rendered. Pointing Dependabot's `gomod` ecosystem at a deliberately invalid template cannot work.

**Action:** remove that ecosystem entry until a valid generated fixture is tracked, or make the profile source itself parseable with a replaceable valid default module.

### R9 — Core neutrality and generated-doc completeness remain unfinished

- `init-project/templates/core/docs/requirements.md` always emits AI/RAG sections and LLM-budget text for non-AI projects.
- Python's library-doc block always emits OpenAI, Anthropic, LangChain, Chroma, pgvector, Streamlit, and Gradio links regardless of Q4-Q8.
- `init-project/templates/core/docs/gotchas.md:33` still assumes `~/ForgeWorks/`.
- Rich interview answers still leave positioning, in-scope items, business goals, acceptance criteria, security answers, constraints, and several AI details as TODOs.

**Action:** make capability-specific content conditional and render every known interview answer into a versioned project spec.

## Portfolio and repository finish

- Protect `main` and require the root CI checks. It is currently unprotected.
- Restore/enable a repository PR template, add issue forms and a code of conduct if outside contributions are desired; community health is 71%, not complete.
- Add topics, a homepage/demo URL, and a short terminal recording. The repository currently has none.
- Add a CI badge only after the next release tag is green.
- Triage/rebase the nine open Dependabot PRs; most show stale source-check failures, while the Vitest 4 pair reveals a real coordinated-major upgrade requirement.
- Remove local `.DS_Store` files before packaging. They are ignored but still present in three source directories.
- Split `init-project/SKILL.md` (744 lines) into the main workflow plus referenced profile/conditional resources, or revise the line-cap rule honestly.
- Pin Actions to full SHAs, pin Context7/images, and verify installer downloads as already promised in the roadmap.

## Recommended sequence for Claude

1. Fix R2, R3, R5, R6, R7, and R8; add regression checks for each.
2. Correct CI wording and add at least one scripted complete no-AI render plus one AI render with hostile names.
3. Protect `main`, rebase/triage Dependabot PRs, and confirm current main is green.
4. Cut a new versioned release without moving `v1.1.0`; verify the exact tag's full CI before changing README pins. Enable GitHub release immutability first if you want to call it immutable.
5. Publish the demo and portfolio copy with “agent-driven beta” language; keep deterministic rendering and supply-chain pinning visibly on the roadmap.
