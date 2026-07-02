# ForgeWorks portfolio-readiness verification

**Verified:** 2026-06-30

**Release:** `v1.1.1` / `86a2f4d` (header corrected 2026-07-02: this audit ran against the v1.1.1 commit; the `v1.1.3` tag is `4348008`)

**Purpose:** independent verification after the v1.0.0 and v1.1.0 audit remediations.

> **Status update (2026-07-02).** This document is a historical snapshot; the release-quality items below have since been fixed and verified:
> - **V1 (render smoke skips dotfiles): FIXED** in v1.1.2 -- `render_smoke.py` now walks with `os.walk` and asserts sentinel dotfiles were rendered; the render is exercised in CI on every push.
> - **V2 guard flag variants: FIXED** -- `npx -y` / `--yes`, `uvx --from`, and `npm --prefix . test` behave correctly and are in the CI regression suite, which was later extended with quoted-package, compound-command, and pipe-to-shell cases.
> - **V2 wording drift: FIXED** in v1.1.2/v1.1.3 (pre-commit/pnpm claims, "only Python complete", gotchas count, line-cap exemption for skills).
> - The remaining V2 presentation/roadmap items (deterministic renderer, SHA pinning, homepage/demo) stay tracked in `docs/ROADMAP.md`.

## Verdict

ForgeWorks is now credible as a **transparent engineering beta and portfolio project**. The exact release commit is green, the three advertised profiles pass their quality gates, the known TypeScript vulnerabilities are removed, Go is supported and lint-enforced, upgrade provenance is preserved, and repository governance/security settings are substantially stronger.

It is still not a deterministic production bootstrapper: generation remains an AI agent executing `init-project/SKILL.md`, and supply-chain pinning is explicitly deferred. Those limitations are now stated honestly in README and ROADMAP.

**Before calling the portfolio review finished, fix V1 below.** It is a real false-positive in the new render test. The remaining V2 items are polish or acknowledged roadmap work.

| Area | v1.0.0 | v1.1.1 | Assessment |
|---|---:|---:|---|
| Product and positioning | 8/10 | 8/10 | Strong, differentiated product idea. |
| First-use UX | 5/10 | 7/10 | Setup contradictions largely removed; full flow is still agent-driven. |
| Generator evidence | 3/10 | 6/10 | Profile gates and render smoke exist; hidden-file coverage is currently broken. |
| Language profiles | 4/10 | 9/10 | Python, TypeScript, and Go pass on the release commit; TS audit is clean. |
| Upgrade safety | 3/10 | 7/10 | Stamp and profile-specific guidance fixed; automated upgrade fixtures remain future work. |
| Security posture | 4/10 | 7/10 | Reporting/protection/scanning enabled; guard is correctly framed as best-effort. |
| README and docs | 6/10 | 8/10 | Honest status and roadmap; a few contributor/template statements still drift. |
| Open-source polish | 4/10 | 8/10 | Community health 100%, protected main, CI, policy files, topics, and release. |

## Verified resolved

- Release `v1.1.1` points at the audited commit; `VERSION` was `1.1.1` and the installer/docs were pinned to that tag.
- Exact release CI run [28442058120](https://github.com/Kpakfar/ForgeWorks/actions/runs/28442058120) passed sources, render-smoke, deps-guard, Python, TypeScript, and Go jobs.
- `CLAUDE.md` is again a real `120000` symlink to `AGENTS.md`, and CI protects it.
- Python profile: manifest rename is explicit; QA and JSONC-aware pre-commit were previously re-tested green.
- TypeScript profile: QA/e2e pass and `npm audit --audit-level=high` reports zero vulnerabilities.
- Go profile: Go 1.25 plus required golangci-lint v2 pass in CI; lint can no longer silently skip.
- Upgrade kit installation preserves the source version stamp; stamping occurs only after successful QA.
- Upgrade instructions now keep each language's real profile runner and define Python, TypeScript, and Go tooling deltas.
- Private vulnerability reporting is enabled and `SECURITY.md` no longer sends vulnerabilities to public issues.
- `main` is protected with all six CI contexts required; force pushes and deletion are disabled.
- GitHub community profile is 100%; SECURITY, CONTRIBUTING, code of conduct, PR template, MIT license, topics, Dependabot alerts, secret scanning, and push protection are present.
- README and roadmap correctly report Go as CI-verified and describe cross-agent/supply-chain limitations honestly.
- Go Dependabot parsing failures were addressed by removing the invalid `gomod` target; TS and Actions update checks succeed.
- The prior guard bypass set (`npm --prefix`, npx/dlx/exec/uvx, `DEPS_VETTED=0`, cargo/go/pipx) is now represented in a CI regression suite.
- Project-specific `RADAR`, Pydantic/Zod core examples, and `~/ForgeWorks` paths were removed; non-AI requirements are fenced for conditional removal.

## V1 — remaining release-quality defect

### Render smoke silently skips every dotfile

`.github/scripts/render_smoke.py:73-89` enumerates files with `glob.glob("**/*", recursive=True)`. Python glob does not match names beginning with `.`, so the script copies but never substitutes or inspects:

- `.claude/` agents and hooks
- `.github/` workflow and PR template
- `.devcontainer/`
- `.pre-commit-config.yaml`
- `.env.example`, `.mcp.json`, and `.gitignore`

Reproduced against the Python render: `render()` returned `[]` (“clean”), while a hidden-aware scan found unresolved `{{QA_COMMAND}}`, `{{CODEX_REVIEW_STEP}}`, `{{CI_SETUP_STEPS}}`, `{{E2E_COMMAND}}`, `{{PROJECT_NAME}}`, `{{PRECOMMIT_INSTALL_COMMAND}}`, and `{{LANGUAGE_PRECOMMIT_HOOKS}}` in hidden paths.

This makes the green `render-smoke` job materially weaker than CI comments and CONTRIBUTING claim.

**Fix:** enumerate with `Path(out).rglob("*")` or `os.walk`, for both substitution and leftover detection. Add an assertion that at least `.claude/hooks/quality-gate.sh`, `.github/workflows/qa.yml`, and the selected profile's hidden files were visited. Then validate rendered JSON/YAML/TOML and executable modes. Add no-AI and AI cases when the conditional engine becomes deterministic.

## V2 — follow-up quality work

### Dependency guard flag variants

The new suite covers the original bypasses, but current retest still allows `npx -y package`, `npx --yes package`, and `uvx --from package command`. Conversely, `npm --prefix . test` is blocked even though it installs nothing. This is acceptable only under the documented “best-effort speed bump” claim.

**Fix:** let remote-execute patterns consume flags before the package and narrow `npm --prefix` matching to install/add/exec operations. Add these cases to `deps_guard_test.sh`.

### Contributor and skill wording drift

- `AGENTS.md:58` still says the only validation is a manual bootstrap, despite root smoke CI.
- `bootstrap/AGENTS.md:42,47` implies every profile has pre-commit and uses `pnpm`; TypeScript uses npm and only Python ships pre-commit.
- `init-project/SKILL.md:711` calls Python the only fully-supported profile; all three are advertised complete.
- `init-project/SKILL.md:153,259` says “two starter entries” but contains three.
- `init-project/SKILL.md` is 744 lines despite the repository's 200-line hard cap.

**Fix:** correct the four stale statements. Split the skill into the main workflow plus directly referenced profile/conditional resources, or explicitly exempt skills from the line cap.

### Rendered product documentation

AI-specific requirements are now fenced correctly, but many interview answers still become TODOs: positioning, in-scope items, business goals, acceptance criteria, security answers, and constraints. Python library links also list AI/UI tools regardless of selected capabilities.

**Fix:** move toward the roadmap's versioned project specification and capability fragments so known answers render as content and irrelevant sections do not ship.

### Repository presentation and maintenance

- The release is versioned but GitHub reports `immutable: false`; this is accurately disclosed.
- Nine older Dependabot PRs remain open with stale checks; one current Actions PR is green. Rebase/close superseded PRs and coordinate paired majors such as Vitest + coverage.
- Add a homepage/demo URL and a short terminal recording; topics now exist but `homepage` is empty.
- The code-of-conduct reporting path reuses security advisories. Prefer a dedicated conduct contact instead of mixing vulnerability and community reports.
- Supply-chain hardening remains open as documented: full-SHA Actions, pinned Context7/container images, and verified remote installers.

## Final recommendation

1. Fix the hidden-file render traversal and add its regression assertion.
2. Correct the small wording drift and update the guard's flagged variants.
3. Re-run the exact commit through all required checks; cut a patch release only if generated files or published pins change.
4. Publish the portfolio as an **agent-driven engineering harness in active development**, with the CI run and demo as evidence. Do not call generation deterministic until the roadmap renderer exists.
