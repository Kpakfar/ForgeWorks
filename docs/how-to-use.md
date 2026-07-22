# How to use this template

## Starting a new project

Two equivalent options:

### Option A: One-line install (recommended)

```bash
mkdir my-new-project && cd my-new-project && git init
bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v2.5.0/bootstrap/install.sh)
```

Then open Claude Code and run `/init-project`.

### Option B: manual (curl + degit, no `bash <(curl ...)`)

```bash
mkdir my-new-project && cd my-new-project && git init
curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v2.5.0/bootstrap/AGENTS.md -o AGENTS.md
mkdir -p .claude/skills
npx degit Kpakfar/ForgeWorks/init-project#v2.5.0 .claude/skills/init-project --force
```

Then open Claude Code and run `/init-project`.

## What happens during bootstrap

1. The skill confirms intent with you.
2. It runs `npx skills@latest add mattpocock/skills` (you pick which skills).
3. It interviews you (scope, the heart of the project, stack, security profile, dev container, and more).
4. It writes your answers to `docs/_init-answers.json` and runs the bundled deterministic renderer (`render.py`), which generates the project from the universal core + your chosen language profile — same answers, same bytes, verified by golden-fixture CI in the template repo.
5. The renderer symlinks `CLAUDE.md` → `AGENTS.md` and stamps the template version at `.claude/.template-version`.
6. It offers to remove the init skill from the project — optional cleanup, since the skill isn't needed once generation is done; keeping it does no harm.

## Upgrading an existing project to a newer template

Run the **same install command** inside an already-generated project. `install.sh` detects it (via `.claude/agents/` or a non-bootstrap `AGENTS.md`) and installs the `/upgrade-project` skill instead of bootstrapping:

```bash
# In your existing project, commit your work first, then:
bash <(curl -fsSL https://raw.githubusercontent.com/Kpakfar/ForgeWorks/v2.5.0/bootstrap/install.sh)
```

Open Claude Code and run `/upgrade-project`. It reconciles the project against the current template:

- **Copies** new always-on files that are missing (e.g. `docs/SECURITY.md`, the deps-guard hook, the security-reviewer / tech-debt subagents).
- **Grafts** new `AGENTS.md` rule blocks and subagent sections into your existing files **without overwriting** your hand-filled content.
- **Applies** the language tooling delta (markers, deps, the e2e CI job for supported languages).
- **Reports** what still needs a manual look.

It is non-destructive and idempotent — safe to run more than once. **Do not** re-run `/init-project` on an existing project; that overwrites your filled-in docs.

## Updating the template itself

Edit files in this repo. Your edits are picked up only by a bootstrap that targets the branch you edited (`BRANCH=main`, per the repo `AGENTS.md` `<testing-changes>`); the published, pinned one-liner stays at the released tag (`v2.5.0`) until a new release is cut, so it keeps producing the released template. Existing projects can pull merged changes via `/upgrade-project` above.

Backporting lessons from a real project: read that project's `docs/gotchas.md` (and reviewer notes) at the end, and for each *generic* lesson edit the corresponding file here and push. When a change alters the generated structure, bump `VERSION` and — if it adds tooling or placeholder-bearing files — extend `upgrade-project/SKILL.md` (see the repo `AGENTS.md` `<editing-the-upgrade-skill>`).

## Adding a new language

The shared `init-project/templates/core/` serves every language; each language is a **profile folder** plus a YAML block. A generated project is `core/` + one profile, so nothing language-specific leaks across languages. To add one:

1. Create `init-project/templates/profiles/<lang>/` with: the manifest, toolchain config, a verify-only `qa` runner + a separate `fix` runner + a separate `e2e` runner, a **green-on-first-run scaffold** (a typed example + a passing test), `.gitignore`, a hardened dev container, and (only if idiomatic) a pre-commit config. Mirror the shape of `templates/profiles/python/` (or `typescript/` / `go/` / `rust/`).
2. Add a YAML block to `init-project/SKILL.md` `<language-profiles>` with the same keys as Python (`language_version`, `package_manager`, `manifest_file`, `qa_command`, `fix_command`, `e2e_command`, `ci_setup_steps`, `notes`, ...) and the matching machine-readable `profile.json` in the profile folder (the renderer's input — keep the two in sync).
3. Add the language to B1's menu (mark `[complete]` only once it passes) and to `render.py`'s language list.
4. Add a golden fixture for the language and commit its expected tree (`python3 .github/scripts/golden_test.py --update`).
5. Bootstrap a throwaway project in that language and confirm `qa` is **green on the first run**.

**Python, TypeScript, Go, and Rust** are complete profiles — all four are verified green in CI on the merged core+profile tree (quality gate + e2e runner). "Other" is not built yet.

## Troubleshooting

**`/init-project` slash command doesn't appear.**
The skill needs to be in `.claude/skills/init-project/SKILL.md` (note: the directory name matters). If `npx degit` put it elsewhere, move it.

**Symlink fails on Windows.**
Use Option A above on WSL, or skip the symlink and use a one-line `CLAUDE.md` pointing to `AGENTS.md` instead: `# See @AGENTS.md for project conventions.`

**Mattpocock skills don't install.**
Make sure Node.js is available. On the host machine, not just the container. The npx skill installer writes to a project-local directory and is then available to all coding agents.
